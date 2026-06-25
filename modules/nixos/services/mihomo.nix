{
  lib,
  pkgs,
  repoTree,
  ...
}:
let
  mihomo-switch = pkgs.callPackage repoTree.packages.mihomo-switch.default { };
  mihomo-get-zashboard = pkgs.callPackage repoTree.packages.mihomo-get-zashboard.default { };
in
{
  environment.systemPackages = [
    mihomo-switch
    mihomo-get-zashboard
  ];

  networking.firewall.allowedTCPPorts = [ 7890 ];

  system.activationScripts.mihomo-init = {
    text = ''
      echo "Running mihomo-init..."
      ${mihomo-get-zashboard}/bin/mihomo-get-zashboard || true
    '';
  };

  services.mihomo = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.unstable.mihomo;
    tunMode = true;
    configFile = "/var/lib/mihomo/config.yaml";
    webui = "/var/lib/mihomo/ui";
  };

  services.caddy.virtualHosts."http://zashboard.localhost" = {
    extraConfig = ''
      rewrite /ui{uri}
      reverse_proxy 127.0.0.1:9090
    '';
  };
}
