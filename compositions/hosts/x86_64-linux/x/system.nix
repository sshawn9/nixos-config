{ lib, ... }:
{
  system.stateVersion = "25.11";
  sharedOptionsUser = "star";
  users.mutableUsers = lib.mkDefault false;

  boot = {
    kernel.sysctl."kernel.nmi_watchdog" = lib.mkDefault 0;
    tmp.useTmpfs = true;
    loader = {
      efi.efiSysMountPoint = "/boot";
      systemd-boot.enable = true;
    };
  };

  home-manager.users.star.fileSources.overrideDirs = lib.mkAfter [ "file-sources/x" ];
}
