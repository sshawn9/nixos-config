{
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [ inputs.bluetooth-auth.nixosModules.bluetooth-auth ];

  my.security.bluetoothAuth = {
    enable = true;

    user = lib.mkDefault config.my.shared.username;
    bluetoothAddressFile = config.sops.secrets.auth_bluetooth_address.path;
    autoConnect = {
      enable = true;
      deviceUnvailableGraceSeconds = 30;
      exceptionGraceSeconds = 30;
    };
    autoLock = {
      enable = false;
      checkIntervalSeconds = 120;
      sleepAfterLockSeconds = 120;
    };
    sudoAuth.enable = true;
    polkitAuth.enable = true;
    lockerAuth.enable = true;
  };

  users.groups.bluetooth-auth.members = [
    config.my.security.bluetoothAuth.user
    "polkituser"
  ];

  sops.secrets.auth_bluetooth_address = {
    group = "bluetooth-auth";
    mode = "0440";
  };
}
