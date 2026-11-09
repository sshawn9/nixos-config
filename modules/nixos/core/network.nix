{
  config,
  lib,
  ...
}:

{
  networking.hostName = config.my.shared.hostname;
  networking.networkmanager.enable = lib.mkDefault true;

  users.users.${config.my.shared.username}.extraGroups =
    lib.mkIf config.networking.networkmanager.enable
      [
        "networkmanager"
      ];
}
