_:

{
  boot = {
    loader = {
      systemd-boot.enable = false;
      grub = {
        enable = true;
        efiSupport = false;
      };
      timeout = 10;
    };
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

  nix.settings = {
    max-jobs = 1;
    cores = 1;
  };

  # This is the installed system's compatibility version, not the flake version.
  system.stateVersion = "26.05";
}
