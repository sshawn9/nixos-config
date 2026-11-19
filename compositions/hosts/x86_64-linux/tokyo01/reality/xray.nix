{
  config,
  pkgs,
  self,
  ...
}:
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

  systemd.services.xray.after = [ "caddy.service" ];
}
