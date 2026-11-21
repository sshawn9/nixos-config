{
  config,
  lib,
  pkgs,
  ...
}:
let
  frontendEntries =
    lib.genAttrs [ "udp" "tcp" "ws" ] (name: config.features.easytier.frontend.${name})
    // {
      default = {
        enable = config.features.easytier.frontend.default.domain != null;
        domain = config.features.easytier.frontend.default.domain;
      };
    };
  frontendFiles = pkgs.fetchzip {
    name = "easytier-web-dashboard";
    url = "https://github.com/EasyTier/EasyTier/releases/download/v2.7.1/easytier-web-dashboard-v2.7.1.zip";
    hash = "sha256-BEupTbUtnpLlp83BcUDqRnsJP+6EYX3BdZMplEnTpQk=";
  };
in
{
  config = lib.mkIf config.features.easytier.enable (
    lib.mkMerge (
      lib.mapAttrsToList (
        name: frontend:
        let
          apiDomain = config.features.easytier.backend.${name}.apiDomain;
          apiMeta = builtins.toJSON "window.apiMeta = ${
            builtins.toJSON { api_host = "https://${toString apiDomain}"; }
          };";
        in
        lib.mkIf frontend.enable {
          assertions = [
            {
              assertion = frontend.domain != null && frontend.domain != "";
              message = "features.easytier.frontend.${name}.domain must be set when that frontend is enabled.";
            }
            {
              assertion = apiDomain != null && apiDomain != "";
              message = "features.easytier.backend.${name}.apiDomain must be set when the ${name} frontend is enabled.";
            }
            {
              assertion = frontend.domain != apiDomain;
              message = "The EasyTier ${name} frontend must use a different domain from its API.";
            }
          ];

          services.caddy.virtualHosts.${toString frontend.domain}.extraConfig = ''
            root * ${frontendFiles}

            @entry path / /index.html
            header @entry Cache-Control "no-cache, no-store, must-revalidate"

            handle /api_meta.js {
              header Content-Type "application/javascript; charset=utf-8"
              header Cache-Control "no-cache, no-store, must-revalidate"
              respond ${apiMeta} 200
            }

            handle {
              file_server
            }
          '';
        }
      ) frontendEntries
    )
  );
}
