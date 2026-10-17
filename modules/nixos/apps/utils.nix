{ config, lib, ... }:
{
  my.packages = {
    cpupower = {
      enable = lib.mkDefault false;
      package = lib.mkDefault config.boot.kernelPackages.cpupower;
    };
    turbostat = {
      enable = lib.mkDefault false;
      package = lib.mkDefault config.boot.kernelPackages.turbostat;
    };
    cpu-x = lib.mkDefault false;
    hwloc = lib.mkDefault false;
    dmidecode = lib.mkDefault false;
    pciutils = lib.mkDefault false;
    usbutils = lib.mkDefault false;
    i2c-tools = lib.mkDefault false;
    nvme-cli = lib.mkDefault false;
    smartmontools = lib.mkDefault false;
  };
}
