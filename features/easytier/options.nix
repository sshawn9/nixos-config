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

    client = {
      enable = lib.mkEnableOption "the EasyTier Config Server client";

      configServer = lib.mkOption {
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default = null;
        example = "https://et-config.example.com/DEVICE_TOKEN";
        description = ''
          Full Config Server URL, including the protocol, host, port when
          needed, and device token path. Accepts HTTPS address discovery or
          direct UDP/TCP/WS/WSS connections. Required when the client is enabled.
        '';
      };
    };

    relay = {
      enable = lib.mkEnableOption "the EasyTier shared relay node";

      port = lib.mkOption {
        type = lib.types.ints.between 1 65532;
        default = 11010;
        description = ''
          Base port for all seven relay protocols: TCP/UDP use this port,
          WireGuard/WS use port + 1, QUIC/WSS use port + 2, and FakeTCP uses
          port + 3. The upper bound leaves room for all derived ports.
        '';
      };
    };

    backend = {
      default = {
        type = lib.mkOption {
          type = lib.types.enum [
            "udp"
            "tcp"
            "ws"
            "wss"
          ];
          default = "tcp";
          description = "Default Config Server transport and corresponding API backend; WS and WSS share the WS backend.";
        };

        apiDomain = lib.mkOption {
          type = lib.types.nullOr lib.types.nonEmptyStr;
          default = null;
          example = "et-api.example.com";
          description = "Optional HTTPS API hostname, served as an alias of the selected backend API.";
        };

        configDomain = lib.mkOption {
          type = lib.types.nullOr lib.types.nonEmptyStr;
          default = null;
          example = "et-config.example.com";
          description = ''
            Public Config Server hostname, without a scheme. HTTPS requests
            discover the default connection address; WebSocket upgrades connect
            to the WS backend when it is enabled. Resolve this hostname directly
            to the server, since the discovered UDP/TCP/WS addresses also use it.
          '';
        };
      };

      udp = mkBackendOptions {
        apiPort = 11211;
        configPort = 22020;
      };

      tcp = mkBackendOptions {
        apiPort = 11212;
        configPort = 22021;
      };

      ws = mkBackendOptions {
        apiPort = 11213;
        configPort = 22022;
      };
    };

    frontend = {
      default = {
        domain = lib.mkOption {
          type = lib.types.nullOr lib.types.nonEmptyStr;
          default = null;
          example = "et.example.com";
          description = "Optional main frontend domain; API requests use backend.default.apiDomain.";
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
