{
  self,
  inputs,
  ...
}:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = self.outPath + "/sops/secrets/secrets.yaml";

    age.sshKeyPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
    ];

    secrets = {
      auth_bluetooth_address = { };
      easytier_config_server = {
        restartUnits = [ "easytier-default.service" ];
      };
      user_password_hash = {
        neededForUsers = true;
      };
    };
  };
}
