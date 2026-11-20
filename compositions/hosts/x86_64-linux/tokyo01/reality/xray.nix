{
  config,
  pkgs,
  self,
  ...
}:
let
  domain = "hello.sshawn9.com";
in
{
  sops.secrets.xrayConfig = {
    sopsFile = self.outPath + "/secrets/tokyo01/xray.enc.json";
    format = "json";
    key = "";
    restartUnits = [ "xray.service" ];
  };

  services.xray = {
    enable = true;
    package = pkgs.unstable.xray;
    settingsFile = config.sops.secrets.xrayConfig.path;
  };

  services.caddy = {
    package = pkgs.unstable.caddy.withPlugins {
      plugins = [ "github.com/mholt/caddy-l4@v0.1.3" ];
      hash = "sha256-N4LqqEcmChyzsTBSC0/6htPYyLoAi15mMaTm7djgEYs=";
    };

    globalConfig = ''
      servers :443 {
        listener_wrappers {
          layer4 {
            @reality tls sni ${domain}
            route @reality {
              proxy {
                proxy_protocol v2
                upstream tcp/127.0.0.1:24443
              }
            }
          }
          tls
        }
      }

      servers 127.0.0.1:8443 {
        protocols h1 h2
      }
    '';

    virtualHosts = {
      "http://${domain}" = {
        logFormat = null;
        extraConfig = ''
          redir https://${domain}{uri} permanent
        '';
      };

      ${domain} = {
        logFormat = null;
        extraConfig = ''
          tls {
            issuer acme {
              disable_tlsalpn_challenge
            }
          }

          root * ${./site}
          file_server
        '';
      };

      # 回落监听独立绑定本机，按 SNI 复用域名站点管理的证书。
      "https://:8443" = {
        listenAddresses = [ "127.0.0.1" ];
        logFormat = null;
        extraConfig = ''
          root * ${./site}
          file_server
        '';
      };
    };
  };

  systemd.services.xray.after = [ "caddy.service" ];
}
