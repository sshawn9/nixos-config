{
  inputs,
  pkgs,
  ...
}:
let
  mihomo-switch = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.mihomo-switch;
  mihomo-get-zashboard =
    inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.mihomo-get-zashboard;
in
{
  environment.systemPackages = [
    mihomo-switch
    mihomo-get-zashboard
  ];

  system.activationScripts.mihomo-init = {
    text = ''
      echo "Running mihomo-init..."
      ${mihomo-get-zashboard}/bin/mihomo-get-zashboard || true
    '';
  };

  launchd.daemons.mihomo = {
    serviceConfig = {
      Label = "mihomo";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          for i in $(seq 1 60); do
            if [ -x "${pkgs.unstable.mihomo}/bin/mihomo" ]; then
              break
            fi
            sleep 1
          done

          exec ${pkgs.unstable.mihomo}/bin/mihomo -d /var/lib/mihomo -f /var/lib/mihomo/config.yaml
        ''
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/lib/mihomo/mihomo.log";
      StandardErrorPath = "/var/lib/mihomo/mihomo.err.log";
    };
  };
}
