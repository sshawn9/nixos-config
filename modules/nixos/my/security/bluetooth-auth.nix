{
  config,
  inputs,
  lib,
  ...
}:

let
  cfg = config.my.security.bluetoothAuth;
in
{
  imports = [ inputs.bluetooth-auth.nixosModules.bluetooth-auth ];

  my.security.bluetoothAuth = {
    enable = lib.mkDefault false;
    trustedUser = lib.mkDefault config.my.shared.username;

    device.address = {
      sopsSecretName = "auth_bluetooth_address";
    };

    autoConnect.enable = lib.mkDefault true;

    noctaliaAutoLock = {
      enable = lib.mkDefault true;
    };

    auth = {
      sudo.enable = lib.mkDefault true;
      polkit.enable = lib.mkDefault true;
      locker.enable = lib.mkDefault true;
      greetd.enable = lib.mkDefault true;
    };

    gnomeKeyringUnlock = {
      enable = lib.mkDefault true;
      password = {
        sopsFile = ../../../../sops/secrets/keyring.yaml;
        sopsField = "password";
        ageKeyFile = config.home-manager.users.${cfg.trustedUser}.sops.age.keyFile;
      };
    };
  };

  assertions = [
    {
      assertion = cfg.enable -> cfg.device.address.file != "";
      message = ''
        my.security.bluetoothAuth.enable requires device.address.sopsSecretName or device.address.file.
        Fill in the phone identity address secret name or an existing runtime address file.
      '';
    }
  ];
}
