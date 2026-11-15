{ lib, ... }:
{
  networking.hostName = "x";
  networking.networkmanager.enable = lib.mkDefault true;
  time.timeZone = lib.mkDefault "Asia/Shanghai";
  system.stateVersion = "25.11";

  boot = {
    tmp.useTmpfs = true;
    loader = {
      efi.efiSysMountPoint = "/boot";
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 20;
      timeout = 2;
    };
  };

  home-manager.users.star.fileSources.overrideDirs = lib.mkAfter [ ".dotfiles/x" ];
}
