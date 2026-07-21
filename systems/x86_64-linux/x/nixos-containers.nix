{
  config,
  lib,
  pkgs,
  ...
}:
let
  dockerLegacyHostAddress = "10.233.1.1";
  dockerLegacyLocalAddress = "10.233.1.2";
  dockerLegacyInterface = "ve-docker+";
  mihomoDnsPort = 1053;

  mihomoDnsRedirect = pkgs.writeShellScript "mihomo-docker-legacy-dns-redirect" ''
    set -eu

    is_listening() {
      ${pkgs.iproute2}/bin/ss -H -lnu 'sport = :${toString mihomoDnsPort}' | ${pkgs.gnugrep}/bin/grep -q . \
        && ${pkgs.iproute2}/bin/ss -H -lnt 'sport = :${toString mihomoDnsPort}' | ${pkgs.gnugrep}/bin/grep -q .
    }

    add_rules() {
      for proto in udp tcp; do
        if ! ${pkgs.iptables}/bin/iptables -w -t nat -C PREROUTING \
          -i '${dockerLegacyInterface}' -p "$proto" --dport 53 \
          -j REDIRECT --to-ports '${toString mihomoDnsPort}' 2>/dev/null; then
          if ! ${pkgs.iptables}/bin/iptables -w -t nat -A PREROUTING \
            -i '${dockerLegacyInterface}' -p "$proto" --dport 53 \
            -j REDIRECT --to-ports '${toString mihomoDnsPort}'; then
            remove_rules
            return 1
          fi
        fi
      done
    }

    remove_rules() {
      for proto in udp tcp; do
        while ${pkgs.iptables}/bin/iptables -w -t nat -D PREROUTING \
          -i '${dockerLegacyInterface}' -p "$proto" --dport 53 \
          -j REDIRECT --to-ports '${toString mihomoDnsPort}' 2>/dev/null; do :; done
      done
    }

    case "''${1:-}" in
      wait-add)
        for _ in $(${pkgs.coreutils}/bin/seq 1 100); do
          if is_listening; then
            add_rules
            exit 0
          fi
          ${pkgs.coreutils}/bin/sleep 0.1
        done
        echo "Mihomo DNS is not listening on TCP and UDP port ${toString mihomoDnsPort}; leaving direct DNS enabled" >&2
        ;;
      sync)
        if is_listening; then
          add_rules
        else
          remove_rules
        fi
        ;;
      remove)
        remove_rules
        ;;
      *)
        echo "usage: $0 {wait-add|sync|remove}" >&2
        exit 2
        ;;
    esac
  '';
in
{
  networking.firewall = {
    trustedInterfaces = [ dockerLegacyInterface ];

    # Firewall reloads remove custom NAT rules. Reconcile them with the
    # listener instead of blindly redirecting DNS to a closed port.
    extraCommands =
      if config.services.mihomo.enable then
        "${mihomoDnsRedirect} sync"
      else
        "${mihomoDnsRedirect} remove";
    extraStopCommands = "${mihomoDnsRedirect} remove";
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

        virtualisation.docker = {
          enable = lib.mkDefault true;
          package = lib.mkDefault pkgs.unstable.docker;
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

  # Start the redirect only after Mihomo's DNS listener is ready. BindsTo also
  # removes it when Mihomo is stopped or crashes. Without the redirect, the
  # container falls back to the host resolv.conf supplied by systemd-nspawn.
  systemd.services.mihomo.wants = lib.mkIf config.services.mihomo.enable [
    "mihomo-docker-legacy-dns-redirect.service"
  ];

  systemd.services."mihomo-docker-legacy-dns-redirect" = lib.mkIf config.services.mihomo.enable {
    description = "Redirect docker-legacy DNS through Mihomo when available";
    bindsTo = [ "mihomo.service" ];
    after = [
      "firewall.service"
      "mihomo.service"
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${mihomoDnsRedirect} wait-add";
      ExecStop = "${mihomoDnsRedirect} remove";
    };
  };
}
