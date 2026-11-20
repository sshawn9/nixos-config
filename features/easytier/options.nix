{ lib, ... }:
let
  mkBackendOptions =
    { apiPort, configPort }:
    {
      enable = lib.mkEnableOption "the EasyTier Web backend";

      apiDomain = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "et-api.example.com";
        description = "Public HTTPS API hostname for this backend.";
      };

      apiPort = lib.mkOption {
        type = lib.types.port;
        default = apiPort;
        description = "Loopback HTTP API port behind Caddy.";
      };

      configPort = lib.mkOption {
        type = lib.types.port;
        default = configPort;
        description = "Native configuration listener port, opened for this backend's protocol.";
      };

      environmentFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/run/secrets/easytier-web.env";
        description = ''
          Runtime environment file for this backend, for example containing
          ET_INTERNAL_AUTH_TOKEN. Secrets must not be written into the Nix store.
        '';
      };
    };
in
{
  options.features.easytier = {
    enable = lib.mkEnableOption "EasyTier";

    backend = {
      udp = mkBackendOptions {
        apiPort = 11211;
        configPort = 22020;
      };

      tcp = mkBackendOptions {
        apiPort = 11212;
        configPort = 22021;
      };

      ws =
        mkBackendOptions {
          apiPort = 11213;
          configPort = 22022;
        }
        // {
          wssDomain = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "et-config.example.com";
            description = ''
              Public WSS hostname, without a scheme. Caddy terminates TLS on
              port 443 and forwards to this backend's native WS listener.
            '';
          };
        };
    };

    frontend = {
      default = {
        type = lib.mkOption {
          type = lib.types.enum [
            "udp"
            "tcp"
            "ws"
          ];
          default = "tcp";
          description = "Frontend served at frontend.default.domain; that frontend must be enabled.";
        };

        domain = lib.mkOption {
          type = lib.types.nullOr lib.types.nonEmptyStr;
          default = null;
          example = "et.example.com";
          description = "Optional main domain, served as an alias of the selected frontend.";
        };
      };
    }
    //
      lib.genAttrs
        [
          "udp"
          "tcp"
          "ws"
        ]
        (protocol: {
          enable = lib.mkEnableOption "the EasyTier ${protocol} frontend";

          domain = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "et-${protocol}.example.com";
            description = "Domain served by Caddy for the ${protocol} dashboard.";
          };
        });
  };
}
