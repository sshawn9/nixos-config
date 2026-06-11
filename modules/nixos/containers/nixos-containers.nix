{
  lib,
  pkgs,
  ...
}:
let
  dockerLegacyHostAddress = "10.233.1.1";
  dockerLegacyLocalAddress = "10.233.1.2";
  dockerLegacyInterface = "ve-docker+";
  mihomoDnsPort = 1053;
in
{
  networking.firewall = {
    trustedInterfaces = [ dockerLegacyInterface ];

    extraCommands =
      lib.concatMapStringsSep "\n"
        (proto: ''
          iptables -w -t nat -C PREROUTING -i ${dockerLegacyInterface} -p ${proto} --dport 53 -j REDIRECT --to-ports ${toString mihomoDnsPort} 2>/dev/null ||
            iptables -w -t nat -A PREROUTING -i ${dockerLegacyInterface} -p ${proto} --dport 53 -j REDIRECT --to-ports ${toString mihomoDnsPort}
        '')
        [
          "udp"
          "tcp"
        ];

    extraStopCommands =
      lib.concatMapStringsSep "\n"
        (proto: ''
          while iptables -w -t nat -D PREROUTING -i ${dockerLegacyInterface} -p ${proto} --dport 53 -j REDIRECT --to-ports ${toString mihomoDnsPort} 2>/dev/null; do :; done
        '')
        [
          "udp"
          "tcp"
        ];
  };

  containers = {
    docker-legacy = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = dockerLegacyHostAddress;
      localAddress = dockerLegacyLocalAddress;
      additionalCapabilities = [
        "CAP_BPF"
        "CAP_MKNOD"
        "CAP_NET_ADMIN"
        "CAP_NET_RAW"
        "CAP_SETFCAP"
        "CAP_SYS_ADMIN"
      ];
      extraFlags = [ "--system-call-filter=bpf" ];
      config = _: {
        system.stateVersion = "25.11";

        networking = {
          useHostResolvConf = lib.mkForce false;
          nameservers = [ dockerLegacyHostAddress ];
        };

        virtualisation.docker = {
          enable = lib.mkDefault true;
          package = pkgs.unstable.docker;
          daemon.settings = {
            features."containerd-snapshotter" = false;
          };
        };
      };
    };
  };

  # Docker/runc manages nested cgroups and device filters inside this nspawn
  # container. The default closed device policy blocks that path on cgroup v2.
  systemd.services."container@docker-legacy".serviceConfig.DevicePolicy = lib.mkForce "auto";
}
