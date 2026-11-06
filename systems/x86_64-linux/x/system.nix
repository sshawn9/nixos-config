_:

{
  my.security.bluetoothAuth.enable = true;

  boot.tmp.useTmpfs = true;

  # boot.kernelPackages = pkgs.stable.linuxPackages_6_18;

  virtualisation.libvirtd.enable = true;

  services.samba.enable = true;
}
