{ inputs, ... }:

{
  imports = [ inputs.disko.nixosModules.disko ];

  # Keep the layout and partition labels used by the original installation.
  # Disko also generates fileSystems, swapDevices, and the BIOS GRUB device.
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        bios = {
          priority = 1;
          size = "1M";
          type = "EF02";
        };
        swap = {
          priority = 2;
          size = "2G";
          content.type = "swap";
        };
        root = {
          priority = 3;
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
