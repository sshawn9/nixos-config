{
  config,
  inputs,
  lib,
  ...
}:

let
  sopsEnabled = config.my.shared.sops.enable;
in
{
  imports = [ inputs.bluetooth-auth.nixosModules.bluetooth-auth ];

  my.security.bluetoothAuth = {
    enable = lib.mkDefault false;

    user = lib.mkDefault config.my.shared.username;
    bluetoothAddressFile = lib.mkIf sopsEnabled config.sops.secrets.auth_bluetooth_address.path;
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

  sops.secrets.auth_bluetooth_address = lib.mkIf sopsEnabled {
    group = "bluetooth-auth";
    mode = "0440";
  };

  assertions = [
    {
      assertion =
        config.my.security.bluetoothAuth.enable
        -> config.my.security.bluetoothAuth.bluetoothAddressFile != "";
      message = ''
        my.security.bluetoothAuth.enable needs bluetoothAddressFile, which normally
        comes from sops. Either enable my.shared.sops or point bluetoothAddressFile
        at a file yourself.
      '';
    }
  ];
}
