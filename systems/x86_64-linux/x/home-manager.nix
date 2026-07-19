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
      home.username = username;

      my = {
        paths.dotfilesLayers.overrideDirs = [ "x" ];
      };
    };
  };
}
