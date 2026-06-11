{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# Why a user service rather than a system service:
#   - awatcher needs access to the current user's Wayland session
#     (wl_display / D-Bus) to subscribe to wlr-foreign-toplevel and
#     ext-idle-notify protocols; this path is not available in the
#     system scope.
#   - Data is stored in ~/.local/share/activitywatch — it is private
#     user data, so there is no need for the system scope.
#
# ⚠️ User action required: the browser extension aw-watcher-web cannot
# be installed declaratively. (The declarative Chrome/Edge extension
# mechanism on NixOS only works under enterprise policy and is not
# suitable for personal use.) If you want URL-level activity tracking,
# install the extension manually from the Chrome Web Store or Edge
# Add-ons and point it to http://localhost:5600.
let
  cfg = config.my.services.activitywatch;
  tomlFormat = pkgs.formats.toml { };
  py = pkgs.unstable.python3Packages;

  # aw-server-rust's config key is `address`, not `host` (see
  # aw-server/src/config.rs in the upstream source).
  serverConfig = lib.recursiveUpdate cfg.watchers.server.settings {
    address = cfg.host;
    inherit (cfg) port;
  };

  awatcherConfig = lib.recursiveUpdate cfg.watchers.awatcher.settings {
    server = {
      inherit (cfg) host port;
    };
    awatcher = {
      "idle-timeout-seconds" = cfg.watchers.awatcher.idleTimeoutSec;
    };
  };

  # Minimal user-scope hardening. ActivityWatch only reads Wayland and
  # D-Bus session state; no privileged capabilities are needed.
  systemdHardening = {
    LockPersonality = true;
    NoNewPrivileges = true;
    RestrictNamespaces = true;
    UMask = "0077";
  };

  aw-watcher-afk-lib = py.buildPythonPackage {
    pname = "aw-watcher-afk";
    inherit (pkgs.unstable.aw-watcher-afk) version src;
    format = "pyproject";
    nativeBuildInputs = [ py.poetry-core ];
    propagatedBuildInputs =
      with py;
      [
        aw-client
        pynput
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ xlib ];
    # Upstream pins `python-xlib = "0.31"` to avoid a 2022-era CPU stall
    # bug; that bug was fixed in 0.33 (which is what nixpkgs ships).
    pythonRelaxDeps = [ "python-xlib" ];
    doCheck = false;
  };

  aw-watcher-input-pkg = py.buildPythonApplication {
    pname = "aw-watcher-input";
    version = inputs.aw-watcher-input-src.shortRev or "unstable";
    format = "pyproject";
    src = inputs.aw-watcher-input-src;
    nativeBuildInputs = [ py.poetry-core ];
    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail \
          'aw-watcher-afk = {git = "https://github.com/ActivityWatch/aw-watcher-afk.git"}' \
          'aw-watcher-afk = "*"'
    '';
    propagatedBuildInputs = [
      py.aw-client
      py.aw-core
      py.click
      aw-watcher-afk-lib
    ];
    doCheck = false;
    meta = {
      description = "ActivityWatch watcher for keyboard and mouse input events";
      homepage = "https://github.com/ActivityWatch/aw-watcher-input";
      license = lib.licenses.mpl20;
      mainProgram = "aw-watcher-input";
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
    };
  };

  aw-watcher-utilization-pkg = py.buildPythonApplication {
    pname = "aw-watcher-utilization";
    version = inputs.aw-watcher-utilization-src.shortRev or "unstable";
    format = "pyproject";
    src = inputs.aw-watcher-utilization-src;
    nativeBuildInputs = [ py.poetry-core ];
    # Upstream pins the legacy `poetry.masonry.api` backend, which only
    # exists in the full `poetry` package — `poetry-core` exposes
    # `poetry.core.masonry.api` instead. Rewrite to modern form so the
    # build works with the lightweight build backend used by nixpkgs.
    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail \
          'aw-core = {git = "https://github.com/ActivityWatch/aw-core.git"}' \
          'aw-core = "*"' \
        --replace-fail \
          'aw-client = {git = "https://github.com/ActivityWatch/aw-client.git"}' \
          'aw-client = "*"' \
        --replace-fail \
          'requires = ["poetry>=0.12"]' \
          'requires = ["poetry-core>=1.0.0"]' \
        --replace-fail \
          'build-backend = "poetry.masonry.api"' \
          'build-backend = "poetry.core.masonry.api"'
    '';
    propagatedBuildInputs = with py; [
      aw-client
      aw-core
      psutil
    ];
    # Upstream pins psutil ^5.9.5 (<6); nixpkgs has 7.x. The API we
    # depend on is stable across the bump, so relax the constraint.
    pythonRelaxDeps = [ "psutil" ];
    doCheck = false;
    meta = {
      description = "ActivityWatch watcher for CPU, RAM, GPU, and disk utilization";
      homepage = "https://github.com/Alwinator/aw-watcher-utilization";
      license = lib.licenses.mpl20;
      mainProgram = "aw-watcher-utilization";
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
    };
  };

  # ── systemd unit factories ──────────────────────────────────────────
  # Two shapes exist in this stack:
  #   - aw-server: the "root" unit. Type=notify, no upstream dep, drives
  #     every other unit through PartOf.
  #   - everything else: heartbeats into aw-server. Requires aw-server
  #     and dies with it.

  mkServerService =
    {
      description,
      exec,
      documentation ? [ ],
    }:
    {
      Unit = {
        Description = description;
        Documentation = documentation;
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        BindsTo = [ "activitywatch.target" ];
      };
      Service = systemdHardening // {
        # Type=notify: aw-server-rust calls sd_notify(READY=1) once Rocket
        # is listening, so dependents can wait for true readiness instead
        # of racing against process start.
        Type = "notify";
        ExecStart = exec;
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "activitywatch.target" ];
    };

  mkWatcherService =
    {
      description,
      exec,
      documentation ? [ ],
      extraService ? { },
    }:
    {
      Unit = {
        Description = description;
        Documentation = documentation;
        After = [
          "aw-server.service"
          "graphical-session.target"
        ];
        Requires = [ "aw-server.service" ];
        # PartOf graphical-session.target: stop cleanly on logout.
        # PartOf aw-server.service: restart with the server so the
        # watcher never keeps heartbeating a stale or missing endpoint.
        PartOf = [
          "graphical-session.target"
          "aw-server.service"
        ];
        BindsTo = [ "activitywatch.target" ];
      };
      Service =
        systemdHardening
        // {
          ExecStart = exec;
          Restart = "on-failure";
          RestartSec = 5;
        }
        // extraService;
      Install.WantedBy = [ "activitywatch.target" ];
    };
in
{
  options.my.services.activitywatch = {
    enable = lib.mkEnableOption "ActivityWatch passive window/AFK telemetry";

    # Default 127.0.0.1: localhost-only access. To expose the web UI to
    # other devices on the LAN, change this to 0.0.0.0 — but you are
    # then responsible for firewall rules and the unencrypted API.
    # Shared by server + every watcher (they all point at this endpoint).
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Bind address for aw-server's REST API.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 5600;
      description = "TCP port for aw-server's REST API.";
    };

    watchers = {
      server = {
        # TODO
        # Keep aw-server-rust on pkgs2511 until aw-webui's test closure is
        # fixed upstream/in nixpkgs. Newer unstable rebuilds aw-webui-0.13.2
        # locally and its nixpkgs checkPhase (`npm test`) fails because
        # @vue/vue2-jest cannot resolve the peer-only vue-template-compiler.
        # Track:
        #   https://github.com/NixOS/nixpkgs/blob/64c08a7ca051951c8eae34e3e3cb1e202fe36786/pkgs/applications/office/activitywatch/default.nix#L208-L253
        #   https://github.com/ActivityWatch/activitywatch/blob/v0.13.2/aw-server-rust/aw-webui/package.json#L12-L13
        #   https://github.com/ActivityWatch/activitywatch/blob/v0.13.2/aw-server-rust/aw-webui/package.json#L84-L92
        #   https://github.com/ActivityWatch/activitywatch/blob/v0.13.2/aw-server-rust/aw-webui/package-lock.json#L26005-L26010
        #   https://github.com/NixOS/nixpkgs/issues/523146
        package = lib.mkPackageOption pkgs.pkgs2511 "aw-server-rust" { };

        settings = lib.mkOption {
          inherit (tomlFormat) type;
          default = { };
          description = ''
            Extra TOML settings for aw-server-rust (e.g. `cors`, `custom_static`).
            `address` and `port` are managed by this module so all local
            consumers share one endpoint.
          '';
        };
      };

      awatcher = {
        package = lib.mkPackageOption pkgs.unstable "awatcher" { };

        idleTimeoutSec = lib.mkOption {
          type = lib.types.ints.positive;
          default = 180;
          description = "Seconds of inactivity before awatcher marks the user AFK.";
        };

        startupDelaySec = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 2;
          description = ''
            Delay before awatcher starts, giving the compositor a window to
            publish Wayland / D-Bus session state to the user manager.
            After+Requires on aw-server.service only guarantees the server
            is ready — not that the graphical session bus is exported.
          '';
        };

        settings = lib.mkOption {
          inherit (tomlFormat) type;
          default = { };
          example = lib.literalExpression ''
            {
              awatcher.filters = [
                {
                  "match-app-id" = "firefox";
                  "match-title" = ".*[sS]ecret.*";
                  "replace-title" = "Hidden";
                }
              ];
            }
          '';
          description = ''
            Extra TOML settings for awatcher. Mainly used for declarative
            title/app filters; endpoint and idle-timeout are managed by the
            typed options in this module.
          '';
        };
      };

      input = {
        package = lib.mkOption {
          type = lib.types.package;
          default = aw-watcher-input-pkg;
          defaultText = lib.literalExpression "inline buildPythonApplication";
          description = "aw-watcher-input derivation. Override to pin a fork.";
        };
      };

      utilization = {
        package = lib.mkOption {
          type = lib.types.package;
          default = aw-watcher-utilization-pkg;
          defaultText = lib.literalExpression "inline buildPythonApplication";
          description = "aw-watcher-utilization derivation. Override to pin a fork.";
        };
      };
    };

    # ── aw-sync (placeholder) ───────────────────────────────────────
    # Left intentionally unimplemented. aw-sync replicates buckets
    # across hosts via a shared directory (Syncthing / SSHFS / NFS).
    # It is only useful if you run aw-server on more than one machine
    # and want a merged view. Enable later by adding a `watchers.sync`
    # subtree + a corresponding systemd.user.services.aw-sync unit
    # that execs `aw-sync` periodically against the shared directory.
    # Upstream docs: https://docs.activitywatch.net/en/latest/features/multidevice.html
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "my.services.activitywatch only supports Linux user sessions.";
      }
    ];

    xdg.configFile = {
      "activitywatch/aw-server-rust/config.toml".source =
        tomlFormat.generate "aw-server-rust-config.toml" serverConfig;

      "awatcher/config.toml".source = tomlFormat.generate "awatcher-config.toml" awatcherConfig;
    };

    systemd.user = {
      # Unified control plane: `systemctl --user {start,stop} activitywatch.target`
      # brings up or tears down every unit in this stack in one step.
      targets.activitywatch = {
        Unit = {
          Description = "ActivityWatch user telemetry stack";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      services = {
        aw-server = mkServerService {
          description = "ActivityWatch server (aw-server-rust)";
          exec = lib.getExe' cfg.watchers.server.package "aw-server";
          documentation = [ "https://docs.activitywatch.net" ];
        };

        awatcher = mkWatcherService {
          description = "awatcher (ActivityWatch window + AFK watcher)";
          exec = "${lib.getExe cfg.watchers.awatcher.package} --config ${config.xdg.configHome}/awatcher/config.toml";
          documentation = [ "https://github.com/2e3s/awatcher" ];
          extraService = lib.optionalAttrs (cfg.watchers.awatcher.startupDelaySec > 0) {
            ExecStartPre = "${pkgs.coreutils}/bin/sleep ${toString cfg.watchers.awatcher.startupDelaySec}";
          };
        };

        aw-watcher-input = mkWatcherService {
          description = "aw-watcher-input (keystroke/mouse counters)";
          exec = lib.getExe cfg.watchers.input.package;
          documentation = [ "https://github.com/ActivityWatch/aw-watcher-input" ];
        };

        aw-watcher-utilization = mkWatcherService {
          description = "aw-watcher-utilization (CPU/RAM/GPU/disk)";
          exec = lib.getExe cfg.watchers.utilization.package;
          documentation = [ "https://github.com/Alwinator/aw-watcher-utilization" ];
        };
      };
    };
  };
}
