{
  config,
  lib,
  pkgs,
  ...
}:
let
  libvirtd = config.virtualisation.libvirtd;
  primaryUser = config.common.primaryUser;
in
{
  config = lib.mkIf config.features.libvirt.enable {
    virtualisation = {
      libvirtd = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.libvirt;
        dbus = {
          enable = lib.mkDefault true;
          package = lib.mkDefault pkgs.unstable.libvirt-dbus;
        };
        qemu = {
          package = lib.mkDefault pkgs.unstable.qemu_kvm;
          vhostUserPackages = [ pkgs.unstable.virtiofsd ];
          swtpm = {
            enable = lib.mkDefault true;
            package = lib.mkDefault pkgs.unstable.swtpm;
          };
        };
      };
      spiceUSBRedirection.enable = lib.mkDefault libvirtd.enable;
    };

    programs = {
      dconf.enable = lib.mkDefault true;
    };

    users.users = lib.mkMerge [
      (lib.mkIf (libvirtd.enable && primaryUser != null) {
        ${primaryUser}.extraGroups = [
          "kvm"
          "libvirtd"
        ];
      })
      (lib.mkIf (libvirtd.enable && libvirtd.dbus.enable) {
        libvirtdbus.extraGroups = [ "libvirtd" ];
      })
    ];

    systemd.tmpfiles.rules = lib.mkIf libvirtd.enable [
      "L+ /var/lib/libvirt/images/virtio-win.iso - - - - ${pkgs.unstable.virtio-win.src}"
    ];
  };
}
