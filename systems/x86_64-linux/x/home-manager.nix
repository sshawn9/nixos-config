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

        services.zeroclaw = {
          enable = true;

          apiKeys = [
            {
              path = "providers.models.opencode.mimo_v2_5_free.api_key";
              secret = "opencode_zamgalang3_key";
            }
          ];
        };
        services.zeroclaw.codexAuth.enable = true;
      };
    };
  };
}
