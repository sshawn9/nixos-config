{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.zeroclaw;

  authFile = lib.escapeShellArg cfg.codexAuth.authFile;

  sopsEnabled = config.my.shared.sops.enable;

  environmentFiles = lib.optional (cfg.environmentFile != null) cfg.environmentFile;

  # Seed ZeroClaw's own encrypted secret store from sops, rather than handing
  # the daemon an environment variable it cannot share with the CLI. Both read
  # `config.toml`, so one write covers both. The value only ever reaches the
  # command line, never the Nix store.
  apiKeySeed = pkgs.writeShellApplication {
    name = "zeroclaw-seed-api-keys";
    runtimeInputs = [ cfg.package ];
    text = lib.concatMapStringsSep "\n" (entry: ''
      if ! zeroclaw config get ${lib.escapeShellArg entry.path} 2>/dev/null | grep -q '\*\*\*\*'; then
        zeroclaw config set --no-interactive ${lib.escapeShellArg entry.path} \
          "$(cat ${lib.escapeShellArg config.sops.secrets.${entry.secret}.path})"
      fi
    '') cfg.apiKeys;
  };

  # Units the daemon must not start before. Collected into one list so the two
  # sources cannot overwrite each other's Wants=/After=.
  daemonAfter = lib.optional cfg.codexAuth.enable "zeroclaw-codex-auth.service";

  codexAuthImport = pkgs.writeShellApplication {
    name = "zeroclaw-codex-auth-import";
    runtimeInputs = [ cfg.package ] ++ lib.optional cfg.codexAuth.stripRefreshToken pkgs.jq;
    text =
      if cfg.codexAuth.stripRefreshToken then
        ''
          # Import a copy with no refresh token: `tokens.refresh_token` is
          # optional to the importer, and without it the daemon can never issue
          # a refresh grant against the identity the Codex CLI still owns.
          filtered="$RUNTIME_DIRECTORY/codex-auth.json"
          jq '{tokens: (.tokens | del(.refresh_token))}' ${authFile} > "$filtered"
          zeroclaw auth login --model-provider openai-codex --import "$filtered"
        ''
      else
        ''
          zeroclaw auth login --model-provider openai-codex --import ${authFile}
        '';
  };
in
{
  options.my.services.zeroclaw = {
    enable = lib.mkEnableOption "ZeroClaw agent daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.zeroclaw-full;
      defaultText = lib.literalExpression "inputs.nix-packages.packages.\${system}.zeroclaw-full";
      description = ''
        Package providing the `zeroclaw` binary.

        Defaults to the `zeroclaw-full` build rather than nixpkgs' own, which
        compiles with Cargo's default features and so leaves out every channel
        outside the lean `default-channels` bundle — WeChat among them. The
        full build also ships shell completions and the gateway's web
        dashboard.
      '';
    };

    apiKeys = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            path = lib.mkOption {
              type = lib.types.str;
              example = "providers.models.opencode.model.api_key";
              description = "Dotted config path of the credential field to fill.";
            };

            secret = lib.mkOption {
              type = lib.types.str;
              example = "opencode_api_key";
              description = "Name of the sops secret holding the raw value.";
            };
          };
        }
      );
      default = [ ];
      description = ''
        Credentials to seed into ZeroClaw's own encrypted store at activation.

        Each entry runs `zeroclaw config set` once, which encrypts the value
        into `config.toml` under the config directory's `.secret_key`. Both the
        daemon and the CLI read that file, so unlike a systemd
        `EnvironmentFile=` this makes one credential work for both, and edits
        made later through the gateway persist instead of being masked back out
        on save.

        The write is skipped when the field already holds a value, so a switch
        does not re-encrypt on every activation. To rotate, clear the field
        first.

        The value passes through the seeding process's command line, so it is
        briefly visible in `/proc` to processes running as the same user. It
        never reaches the Nix store.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "config.sops.secrets.zeroclaw_env.path";
      description = ''
        Optional `KEY=VALUE` file loaded via systemd `EnvironmentFile=`, for
        variables of your own.

        Values such as `ZEROCLAW_providers__models__anthropic__home__api_key=…`
        override the matching config path at load time and are never persisted
        to disk — but they reach only the daemon, not the CLI, and
        `Config::save()` masks them back to the on-disk value. Prefer
        {option}`apiKeys` for credentials.
      '';
    };

    codexAuth = {
      enable = lib.mkEnableOption ''
        re-importing the Codex CLI login into ZeroClaw on a timer.

        OpenAI OAuth refresh tokens are single-use and rotate, and ZeroClaw's
        imported profile is a point-in-time snapshot of `~/.codex/auth.json`
        rather than a live reference. Whichever client refreshes first
        invalidates the other's copy, and `zeroclaw auth refresh` cannot
        recover from it — only a fresh `--import` can. Upstream tracks this as
        zeroclaw-labs/zeroclaw#9492 and has no fix beyond a better error
        message, so the periodic re-import is the working answer
      '';

      package = lib.mkOption {
        type = lib.types.package;
        default = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
        defaultText = lib.literalExpression "inputs.codex-cli-nix.packages.\${pkgs.stdenv.hostPlatform.system}.default";
        description = "Package providing the `codex` binary.";
      };

      authFile = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.codex/auth.json";
        defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/.codex/auth.json"'';
        description = ''
          Codex CLI credential file to import from. The unit is skipped while
          this path does not exist.
        '';
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "6h";
        description = ''
          How often to re-import while the session is up, as a systemd time
          span. The imported access token has been observed to last around 12
          hours, so the default leaves a full period of slack.
        '';
      };

      forceRefresh = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Drive one `codex exec` turn before importing, so the Codex CLI — the
          side that owns the refresh — writes a fresh token to
          {option}`authFile` first.

          Off by default because the turn is a real model call against the
          subscription and buys very little. Upstream states plainly that no
          separate refresh command exists: the CLI renews when `last_refresh`
          passes roughly eight days or when a request comes back `401`, so a
          real run is the only thing that can force it. The access token itself
          has been observed to carry a seven-day expiry, and
          {option}`stripRefreshToken` already removes the daemon's ability to
          rotate the shared credential. Between the two, the cold-start window
          this guards against needs the machine to stay off for about a week.

          Turn it on only if the box really does sit idle that long and the
          import must not land a stale token.
        '';
      };

      stripRefreshToken = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Drop `tokens.refresh_token` from the copy handed to `--import`, so
          the daemon physically cannot rotate a credential the Codex CLI also
          holds. The importer takes the field as an optional one, so a file
          without it loads normally.

          Costs nothing while the token is valid: `AuthService` returns the
          stored access token before it ever looks at the refresh token. Once
          the token is within the 90-second expiry skew the missing field takes
          a branch that hands back the stale token unchanged rather than
          failing, so the request simply gets a 401 from OpenAI and the next
          timer run repairs it.

          What it gives up is self-healing — the daemon can no longer renew on
          its own — which is why {option}`interval` must stay well under the
          token lifetime.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.apiKeys == [ ] || sopsEnabled;
        message = ''
          my.services.zeroclaw.apiKeys reads its values from sops. Enable
          my.shared.sops, or seed the credentials with `zeroclaw config set`
          yourself.
        '';
      }
    ];

    sops.secrets = lib.genAttrs (map (entry: entry.secret) cfg.apiKeys) (_: { });

    home = {
      packages = [ cfg.package ];

      # Runs after sops-nix has decrypted, and only writes fields that are
      # still empty. `zeroclaw config set` rewrites config.toml, so this
      # deliberately happens outside any file the module links.
      activation.seedZeroclawApiKeys = lib.mkIf (cfg.apiKeys != [ ]) (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lib.getExe apiKeySeed}
        ''
      );
    };

    systemd.user = {
      services = {
        zeroclaw = {
          Unit = {
            Description = "ZeroClaw agent daemon";
            Documentation = "https://docs.zeroclawlabs.ai/";
          }
          // lib.optionalAttrs (environmentFiles != [ ]) {
            ConditionPathExists = environmentFiles;
          }
          // lib.optionalAttrs (daemonAfter != [ ]) {
            # Ordering, not just co-scheduling: the key file has to exist, and
            # the daemon must never be the first side to refresh a token the
            # Codex CLI also holds.
            Wants = daemonAfter;
            After = daemonAfter;
          };

          Service = {
            Type = "simple";
            ExecStart = "${lib.getExe cfg.package} daemon";
            Restart = "always";
            RestartSec = 3;
            TimeoutStopSec = 15;
            Environment = [ "HOME=%h" ];
            NoNewPrivileges = true;
            PrivateTmp = true;
            RestrictSUIDSGID = true;
            RestrictRealtime = true;
            LockPersonality = true;
            SystemCallArchitectures = "native";
            UMask = "0077";
          }
          // lib.optionalAttrs (environmentFiles != [ ]) {
            EnvironmentFile = environmentFiles;
          };

          Install.WantedBy = [ "default.target" ];
        };

        zeroclaw-codex-auth = lib.mkIf cfg.codexAuth.enable {
          Unit = {
            Description = "Refresh the Codex CLI session and import it into ZeroClaw";
            Documentation = "https://github.com/zeroclaw-labs/zeroclaw/issues/9492";
            ConditionPathExists = cfg.codexAuth.authFile;
          };

          Service = {
            Type = "oneshot";
            Environment = [ "HOME=%h" ];
            # The filtered copy is written here, on tmpfs, and removed when the
            # unit exits.
            RuntimeDirectory = "zeroclaw-codex-auth";
            RuntimeDirectoryMode = "0700";
            ExecStart =
              lib.optional cfg.codexAuth.forceRefresh "${lib.getExe' cfg.codexAuth.package "codex"} exec --skip-git-repo-check ping"
              ++ [ (lib.getExe codexAuthImport) ];
          };
        };

      };

      timers.zeroclaw-codex-auth = lib.mkIf cfg.codexAuth.enable {
        Unit.Description = "Periodic Codex CLI login re-import for ZeroClaw";

        Timer = {
          # The service also runs at daemon start through the `After=` above, so
          # the first timed run is a full interval into the session rather than a
          # duplicate at login.
          OnStartupSec = cfg.codexAuth.interval;
          OnUnitActiveSec = cfg.codexAuth.interval;
          AccuracySec = "1m";
        };

        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
