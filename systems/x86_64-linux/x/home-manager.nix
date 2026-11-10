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

        services.qbittorrent-nox.enable = true;
        services.caddy.enable = true;
      };
    };
  };
}
