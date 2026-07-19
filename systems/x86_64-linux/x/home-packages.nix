{
  config,
  ...
}:
let
  inherit (config.my.shared) username;
in
{
  home-manager = {
    users.${username} = {
      my = {
        packages = {
          nvtopPackages.full.enable = true;

          ariang.enable = true;

          obsidian.enable = true;
          github-desktop.enable = true;

          google-chrome.enable = true;
          microsoft-edge.enable = true;

          jetbrains = {
            clion.enable = true;
            pycharm.enable = true;
            rust-rover.enable = true;
          };

          telegram-desktop.enable = true;
        };
      };
    };
  };
}
