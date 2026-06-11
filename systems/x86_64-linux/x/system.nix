_:

{
  # Enable keyd for remapping keys on the internal keyboard.
  # Because my interal keyboard meta key is broken.
  # services.keyd = {
  #   enable = true;
  #   keyboards.internal = {
  #     ids = [ "0001:0001" ];
  #     settings.main.leftalt = "leftmeta";
  #   };
  # };

  programs = {
    sniffnet.enable = true;
  };

  my.packages = {
    cpupower.enable = true;
    turbostat.enable = true;
    cpu-x.enable = true;
    hwloc.enable = true;
    dmidecode.enable = true;
    pciutils.enable = true;
    usbutils.enable = true;
    i2c-tools.enable = true;
    nvme-cli.enable = true;
    smartmontools.enable = true;

    llama-cpp.enable = true;
  };

  # boot.kernelPackages = pkgs.stable.linuxPackages_6_18;
}
