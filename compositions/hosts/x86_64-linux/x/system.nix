{ lib, self, ... }:
{
  imports = [ self.nixosModules.star ];

  home-manager.users.star.fileSources.overrideDirs = lib.mkAfter [ "file-sources/x" ];

  system.stateVersion = "25.11";
  users.mutableUsers = lib.mkDefault false;

  boot = {
    tmp.useTmpfs = true;
    loader = {
      efi.efiSysMountPoint = "/boot";
      systemd-boot.enable = true;
    };
  };
}
