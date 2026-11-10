{
  config,
  ...
}:
let
  inherit (config.my.shared) username hostname;
in
{
  home-manager = {
    users.${username} = {
      home.username = username;

      my = {
        paths.dotfilesLayers.overrideDirs = [
          username
          hostname
        ];
      };
    };
  };
}
