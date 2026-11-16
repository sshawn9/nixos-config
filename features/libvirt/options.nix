{ lib, ... }:
{
  options.features.libvirt = {
    enable = lib.mkEnableOption "libvirt/QEMU virtual machines and management tools";
  };
}
