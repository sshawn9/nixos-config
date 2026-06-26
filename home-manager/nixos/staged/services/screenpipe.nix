{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.screenpipe;

  screenpipeLibs = with pkgs; [
    stdenv.cc.cc.lib
    ffmpeg
    alsa-lib
    libpulseaudio
    pipewire
    dbus
    openssl
    lame
    openblas
    tesseract
    xz
    libgbm
    libxcb
    wayland
    libxkbcommon
  ];

  screenpipe = pkgs.writeShellApplication {
    name = "screenpipe";
    runtimeInputs = with pkgs; [
      nodejs
      # JS/TS runtime for screenpipe pipes; without bun `pi agent install` and
      # every pipe invocation fail.
      bun
      ffmpeg
      tesseract
    ];
    text = ''
      # /run/opengl-driver/lib is the NixOS canonical location for NVIDIA
      # userspace (libcuda.so, etc.). Prebuilt CUDA binaries distributed via
      # npm/pip can't find the driver without this prefix, so GPU engines like
      # parakeet silently fall back to CPU.
      export LD_LIBRARY_PATH="/run/opengl-driver/lib:${lib.makeLibraryPath screenpipeLibs}"
      exec npx --yes --prefer-offline screenpipe@latest "$@"
    '';
  };

  startScript = pkgs.writeShellScript "screenpipe-start" ''
    exec ${lib.getExe screenpipe} ${cfg.command}
  '';
in
{
  options.my.services.screenpipe = {
    enable = lib.mkEnableOption "Screenpipe 24/7 screen capture daemon";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3030;
      description = ''
        screenpipe REST API port. Upstream default 3030,
        hardcoded in the screenpipe binary and docs.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = screenpipe;
      defaultText = lib.literalExpression "<generated screenpipe npx wrapper>";
      description = ''
        internally generated wrapper around the upstream screenpipe npm package,
        with LD_LIBRARY_PATH set to include necessary native dependencies.
        No user configuration needed.
      '';
    };

    command = lib.mkOption {
      type = lib.types.str;
      default = ''
        record \
          --retention-days 14 \
          --use-all-monitors \
          --language english \
          --language chinese \
          --video-quality max \
          --disable-audio \
          --pause-on-drm-content \
          --use-pii-removal \
          --disable-telemetry
      '';
      description = ''
        Command-line arguments to pass to the screenpipe binary. The default
        above is a sensible set of options for general-purpose 24/7 capture;
        users can customize as needed. Upstream docs:
        https://docs.screenpi.pe
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ screenpipe ];

    # screenpipe hard-codes $HOME/.bun/bin/bun (bun's official installer path)
    # and ignores PATH. Without this symlink `pi agent install` fails at
    # startup. Once bun is found, screenpipe auto-installs its `pi` CLI
    # alongside it; ~/.bun/bin/ stays a writable real directory.
    home.file.".bun/bin/bun".source = lib.getExe pkgs.bun;

    systemd.user.services.screenpipe = {
      Unit = {
        Description = "Screenpipe local capture daemon";
        Documentation = [ "https://docs.screenpi.pe" ];
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = toString startScript;
        Restart = "on-failure";
        RestartSec = 5;
        Environment = [
          "GTK_MODULES=gail:atk-bridge"
          "GNOME_ACCESSIBILITY=1"
          "QT_ACCESSIBILITY=1"
          "QT_LINUX_ACCESSIBILITY_ALWAYS_ON=1"
        ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
