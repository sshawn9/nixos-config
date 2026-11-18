{ lib, self, ... }:
{
  imports = [ self.nixosModules.star ];

  home-manager.users.star.fileSources.overrideDirs = lib.mkAfter [ "file-sources/x" ];

  system.stateVersion = "26.11";
  users.mutableUsers = lib.mkDefault false;

  nix.settings = {
    max-jobs = 3;
    cores = 16;
  };

  boot = {
    tmp.useTmpfs = true;
    loader = {
      efi.efiSysMountPoint = "/boot";
      systemd-boot.enable = true;
    };
  };
}
