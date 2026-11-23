# Placeholder machine configuration for prebuilding installer targets.
# The installed machine uses Calamares' actual output instead.
{ efi, homeModule }:
{
  networking.hostName = "prebuild";
  common.primaryUser = "prebuild";
  sharedOptionsUser = "prebuild";
  home-manager.users.prebuild = {
    imports = [ homeModule ];
    common.primaryUser = "prebuild";
  };

  hardware.enableAllHardware = true;
  users.allowNoPasswordLogin = true;
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000001";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000002";
    fsType = "vfat";
  };
  boot.loader = {
    systemd-boot.enable = efi;
    efi.canTouchEfiVariables = efi;
    grub = {
      enable = !efi;
      device = if efi then "nodev" else "/dev/vda";
      useOSProber = true;
    };
  };
}
