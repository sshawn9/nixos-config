{ lib, ... }:
{
  boot.kernel.sysctl = {
    "vm.vfs_cache_pressure" = lib.mkDefault 50;
    "vm.dirty_bytes" = lib.mkDefault 268435456;
    "vm.dirty_background_bytes" = lib.mkDefault 67108864;
    "vm.dirty_writeback_centisecs" = lib.mkDefault 1500;
  };

  boot.kernel.sysfs.kernel.mm.transparent_hugepage.defrag = lib.mkDefault "defer+madvise";
}
