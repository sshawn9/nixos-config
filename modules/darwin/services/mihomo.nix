{
  pkgs,
  repoTree,
  ...
}:

let
  mihomo-switch-base = pkgs.callPackage repoTree.packages.mihomo-switch.default { };
  mihomo-switch = pkgs.writeShellScriptBin "mihomo-switch" ''
    export MIHOMO_RESTART_CMD="launchctl kickstart -k system/mihomo"
    exec ${mihomo-switch-base}/bin/mihomo-switch "$@"
  '';
  mihomo-get-zashboard = pkgs.callPackage repoTree.packages.mihomo-get-zashboard.default { };
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
