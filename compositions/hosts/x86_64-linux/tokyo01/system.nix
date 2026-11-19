{
  lib,
  modulesPath,
  self,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    self.nixosModules.star
  ];

  home-manager.users.star.fileSources = {
    localRoot = null;
    overrideDirs = lib.mkAfter [ "file-sources/tokyo01" ];
  };

  system.stateVersion = "26.11";

  # The installed disk boots in BIOS mode.
  boot.loader = {
    systemd-boot.enable = false;
    grub = {
      enable = true;
      efiSupport = false;
    };
    timeout = 10;
  };

  networking = {
    networkmanager.enable = false;
    useDHCP = false;
    useNetworkd = true;
  };

  # Preserve the installed DHCP setup without hardcoding an interface name,
  # private address, gateway, or the public address managed by Tencent Cloud.
  systemd.network.networks."10-uplink" = {
    matchConfig.Driver = "virtio_net";
    networkConfig.DHCP = "ipv4";
    dhcpV4Config.ClientIdentifier = "mac";
  };

  nix = {
    settings = {
      max-jobs = 1;
      cores = 1;
      min-free = 4 * 1024 * 1024 * 1024;
      max-free = 8 * 1024 * 1024 * 1024;
    };

    gc = {
      automatic = true;
      dates = "04:00";
      options = "--delete-older-than 10d";
    };
  };
}
