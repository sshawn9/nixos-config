{
  myLib,
  config,
  ...
}:
let
  inherit (myLib) mkSystemPackages;
in
{
  imports = [
    (mkSystemPackages {
      cpupower = {
        package = config.boot.kernelPackages.cpupower;
      };
      turbostat = {
        package = config.boot.kernelPackages.turbostat;
      };
      cpu-x = { };
      hwloc = { };
      dmidecode = { };
      pciutils = { };
      usbutils = { };
      i2c-tools = { };
      nvme-cli = { };
      smartmontools = { };
    })
  ];
}
