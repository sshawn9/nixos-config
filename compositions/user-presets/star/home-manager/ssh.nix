{
  config,
  lib,
  self,
  ...
}:
{
  config = lib.mkIf (config.features.sops.enable && config.programs.ssh.enable) {
    sops.secrets.sshPrivateKey = {
      sopsFile = self.outPath + "/secrets/star/ssh-private-key.enc.json";
      format = "binary";
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
    };
  };
}
