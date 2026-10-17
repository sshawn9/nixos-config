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
          ariang = true;

          obsidian = true;
          github-desktop = true;

          google-chrome = true;
        };
      };
    };
  };
}
