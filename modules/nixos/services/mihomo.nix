{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  mihomo-switch = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.mihomo-switch;
  mihomo-get-zashboard =
    inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.mihomo-get-zashboard;
in
{
  environment.systemPackages = lib.mkIf config.services.mihomo.enable [
    mihomo-switch
    mihomo-get-zashboard
  ];

  networking.firewall.allowedTCPPorts = lib.mkIf config.services.mihomo.enable [ 7890 ];

  system.activationScripts.mihomo-init = lib.mkIf config.services.mihomo.enable {
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
  systemd.services.mihomo = lib.mkIf config.services.mihomo.enable {
    wantedBy = lib.mkForce [ ];
  };
}
