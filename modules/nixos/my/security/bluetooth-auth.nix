{
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [ inputs.bluetooth-auth.nixosModules.bluetooth-auth ];

  my.security.bluetoothAuth = {
    enable = lib.mkDefault true;

    user = lib.mkDefault config.my.shared.username;
    bluetoothAddressFile = config.sops.secrets.auth_bluetooth_address.path;
    autoConnect = {
      enable = lib.mkDefault true;
      deviceUnvailableGraceSeconds = 30;
      exceptionGraceSeconds = 30;
    };
    autoLock = {
      enable = lib.mkDefault false;
      checkIntervalSeconds = 120;
      sleepAfterLockSeconds = 120;
    };
    sudoAuth.enable = lib.mkDefault true;
    polkitAuth.enable = lib.mkDefault true;
    lockerAuth.enable = lib.mkDefault true;
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
