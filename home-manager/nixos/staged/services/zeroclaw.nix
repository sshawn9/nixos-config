{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.my.paths.local) dotfilesLayeredSource;

  cfg = config.my.services.zeroclaw;

  authFile = lib.escapeShellArg cfg.codexAuth.authFile;

  sopsEnabled = config.my.shared.sops.enable;

  # Every OpenCode Zen alias is served by the same subscription, so they all
  # take the same key. ZeroClaw has no type-level `api_key`, so the key has to
  # be repeated once per alias; the alias list is read straight out of the
  # config the daemon uses, so adding a model needs no change here.
  # Highest-priority dotfiles layer that carries the file, matching how the
  # layered symlink helpers resolve a path.
  zeroclawConfigLayers = lib.filter builtins.pathExists (
    map (layer: config.my.paths.store.dotfilesPath "${layer}/.zeroclaw/config.toml") (
      [ config.my.paths.dotfilesLayers.baseDir ] ++ config.my.paths.dotfilesLayers.overrideDirs
    )
  );

  opencodeAliases =
    if zeroclawConfigLayers == [ ] then
      [ ]
    else
      lib.attrNames (
        (fromTOML (builtins.readFile (lib.last zeroclawConfigLayers))).providers.models.opencode or { }
      );

  apiKeyEnvLines = map (
    alias:
    "ZEROCLAW_providers__models__opencode__${alias}__api_key=${config.sops.placeholder.opencode_zamgalang3_key}"
  ) opencodeAliases;

  # The alias rides inside an environment-variable name, so it is bound by
  # ZeroClaw's alias grammar: lowercase ASCII, digits, single underscores. A
  # hyphen or a dot silently produces a name no shell can export.
  badAliases = lib.filter (
    alias: builtins.match "[a-z0-9](_?[a-z0-9])*" alias == null
  ) opencodeAliases;

  # systemd loads EnvironmentFile= entries in order, so the operator's own file
  # comes last and wins on any collision. Keeping the generated key file as a
  # separate entry leaves `environmentFile` free for unrelated variables.
  environmentFiles =
    lib.optional (apiKeyEnvLines != [ ]) config.sops.templates."zeroclaw.env".path
    ++ lib.optional (cfg.environmentFile != null) cfg.environmentFile;

  # Units the daemon must not start before. Collected into one list so the two
  # sources cannot overwrite each other's Wants=/After=.
  daemonAfter =
    # sops-nix renders the provider-key file during activation; without the
    # ordering the daemon races it and dies on its own ConditionPathExists.
    lib.optional (apiKeyEnvLines != [ ]) "sops-nix.service"
    ++ lib.optional cfg.codexAuth.enable "zeroclaw-codex-auth.service";

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
      default = pkgs.unstable.zeroclaw;
      defaultText = lib.literalExpression "pkgs.unstable.zeroclaw";
      description = ''
        Package providing the `zeroclaw` binary. The nixpkgs build also ships
        the gateway's web dashboard under `$out/bin/web/dist`.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "config.sops.secrets.zeroclaw_env.path";
      description = ''
        Optional `KEY=VALUE` file loaded via systemd `EnvironmentFile=`, for
        variables of your own. It is a separate entry from the sops-rendered
        provider-key file and is loaded after it, so the two never contend and
        yours wins on a collision.

        Only needed to keep credentials out of ZeroClaw's own store: values
        such as `ZEROCLAW_providers__models__anthropic__home__api_key=…`
        override the matching config path at load time and are never persisted
        to disk. Leave it `null` to let `zeroclaw quickstart` manage
        credentials the way it does on any other distribution.
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
        default = true;
        description = ''
          Drive one `codex exec` turn before importing, so the Codex CLI — the
          side that owns the refresh — writes a fresh token to
          {option}`authFile` first.

          This matters after the machine has been off longer than the token
          lifetime: importing the stale file would leave ZeroClaw holding an
          expired token, and its own refresh would then rotate the credential
          out from under the Codex CLI. That is the one direction of the
          conflict that does not heal itself on the next import.

          The turn is a real model call and draws on the subscription's
          allowance. Set to `false` to skip it and accept the cold-start race.
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
    home.packages = [ cfg.package ];

    assertions = [
      {
        assertion = opencodeAliases == [ ] || sopsEnabled;
        message = ''
          The OpenCode Zen key reaches ZeroClaw through sops-nix. Enable
          my.shared.sops, or set my.services.zeroclaw.environmentFile yourself.
        '';
      }
      {
        assertion = badAliases == [ ];
        message = ''
          providers.models.opencode alias(es) ${toString badAliases} fall outside
          ZeroClaw's alias grammar (lowercase ASCII, digits, single underscores;
          no hyphen, no dot). The alias appears verbatim in an
          environment-variable name, so anything else cannot be exported.
        '';
      }
    ];

    sops = lib.mkIf (opencodeAliases != [ ]) {
      secrets.opencode_zamgalang3_key = { };

      templates."zeroclaw.env" = {
        content = lib.concatStringsSep "\n" apiKeyEnvLines;
        mode = "0400";
      };
    };

    home.file = {
      ".zeroclaw/config.toml".source = dotfilesLayeredSource ".zeroclaw/config.toml";

      ".zeroclaw/agents/primary/workspace/AGENTS.md".source =
        dotfilesLayeredSource ".zeroclaw/agents/primary/workspace/AGENTS.md";
      ".zeroclaw/agents/primary/workspace/SOUL.md".source =
        dotfilesLayeredSource ".zeroclaw/agents/primary/workspace/SOUL.md";
      ".zeroclaw/agents/primary/workspace/IDENTITY.md".source =
        dotfilesLayeredSource ".zeroclaw/agents/primary/workspace/IDENTITY.md";
      ".zeroclaw/agents/primary/workspace/USER.md".source =
        dotfilesLayeredSource ".zeroclaw/agents/primary/workspace/USER.md";
      ".zeroclaw/agents/primary/workspace/HEARTBEAT.md".source =
        dotfilesLayeredSource ".zeroclaw/agents/primary/workspace/HEARTBEAT.md";
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
            PassEnvironment = "DISPLAY XDG_RUNTIME_DIR";
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
