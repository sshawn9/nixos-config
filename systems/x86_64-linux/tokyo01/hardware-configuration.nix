{ modulesPath, ... }:

{
  # This profile covers the VirtIO root disk. NixOS's default initrd modules
  # already include ata_piix and sd_mod, so no extra module list is needed.
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
}
