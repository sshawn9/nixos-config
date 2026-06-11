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
      };

      my = {
        paths.dotfilesLayers.overrideDirs = [ "nixos-a2141" ];

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
        };
      };
    };
  };
}
