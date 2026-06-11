{
  lib,
  pkgs,
  ...
}:

{
  services.caddy.virtualHosts."http://homepage.localhost" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:8082
    '';
  };

  systemd.services.homepage-dashboard.serviceConfig = {
    SupplementaryGroups = [
      "docker"
      "podman"
    ];
  };

  services.homepage-dashboard = {
    enable = true;
    package = pkgs.unstable.homepage-dashboard;
    listenPort = 8082;
    openFirewall = true;
    allowedHosts = lib.concatStringsSep "," [
      "homepage.localhost"
      "localhost:8082"
      "127.0.0.1:8082"
    ];

    docker = {
      "docker-rootful" = {
        socket = "/var/run/docker.sock";
      };
    };

    settings = {
      title = "NixOS A2141";
    };

    bookmarks = [
      {
        Host = [
          {
            zashboard = [
              {
                abbr = "ZB";
                href = "http://zashboard.localhost";
              }
            ];
          }
        ];
      }
    ];

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
          cputemp = true;
          uptime = true;
          units = "metric";
          network = true;
        };
      }
      {
        search = {
          provider = "google";
          target = "_blank";
        };
      }
    ];
  };
}
