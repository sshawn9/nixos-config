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
          ariang.enable = true;

          obsidian.enable = true;
          github-desktop.enable = true;

          google-chrome.enable = true;
        };
      };
    };
  };
}
