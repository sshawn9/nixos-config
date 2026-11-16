{ config, lib, ... }:
{
  config = lib.mkIf (config.features.libvirt.enable && config.virtualisation.libvirtd.enable) {
    # Allow guest connections redirected by Mihomo to the host through virbr0.
    networking.firewall = {
      extraCommands = lib.mkIf (config.networking.firewall.backend == "iptables") ''
        iptables -A nixos-fw -i virbr0 \
          -m conntrack --ctstate DNAT -j nixos-fw-accept
      '';

      extraInputRules = lib.mkIf (config.networking.firewall.backend == "nftables") ''
        meta nfproto ipv4 iifname "virbr0" ct status dnat accept
      '';
    };
  };
}
