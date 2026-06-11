{
  pkgs,
  config,
  ...
}:
let
  inherit (config.my.shared) username;
in
{
  home-manager = {
    users.${username} = {
      home.username = username;

      programs = {
        claude-code.enable = true;
        mpv.enable = true;
        vscode.enable = true;
        uv.enable = true;
        mcp.enable = true;
        broot.enable = true;

        aria2.enable = true;
        aria2p.enable = true;

        codex.enable = true;

        htop.package = pkgs.unstable.htop.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [
            ./patches/htop-nvidia-nvml-fallback.patch
          ];

          nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
            pkgs.unstable.makeWrapper
          ];

          postFixup = (oldAttrs.postFixup or "") + ''
            wrapProgram $out/bin/htop \
              --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
          '';
        });
      };

      my = {
        paths.dotfilesLayers.overrideDirs = [ "x" ];

        services = {
          activitywatch.enable = true;
        };
        packages = {
          obsidian.enable = true;
          google-chrome.enable = true;
          antigravity.enable = true;
          code-cursor.enable = true;
          github-desktop.enable = true;
          sqlite.enable = true;
          sqlitebrowser.enable = true;
          regctl.enable = true;
          skopeo.enable = true;
          jetbrains = {
            clion = {
              enable = true;
              package = pkgs.pkgs2511.jetbrains.clion;
            };
            pycharm.enable = true;
            rust-rover.enable = true;
          };
          microsoft-edge.enable = true;
          lm_sensors.enable = true;
          nvtopPackages.full.enable = true;

          cosmic-files.enable = true;
          nemo.enable = true;

          ariang.enable = true;

          rustup.enable = true;

          telegram-desktop.enable = true;

          warp-terminal.enable = true;
        };
      };
    };
  };
}
