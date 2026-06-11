# sudo virsh net-start default
# sudo virsh net-autostart default

{ config, pkgs, ... }:

let
  inherit (config.my.shared) username;
in
{
  virtualisation = {
    libvirtd = {
      enable = true;
      package = pkgs.unstable.libvirt;

      qemu = {
        package = pkgs.unstable.qemu_kvm;
        runAsRoot = true;
        vhostUserPackages = [ pkgs.unstable.virtiofsd ];

        swtpm = {
          enable = true;
          package = pkgs.unstable.swtpm;
        };
      };
    };

    spiceUSBRedirection.enable = true;
  };

  programs = {
    dconf.enable = true;
    virt-manager = {
      enable = true;
      package = pkgs.unstable.virt-manager;
    };
  };

  users.users.${username}.extraGroups = [
    "kvm"
    "libvirtd"
  ];

  environment.systemPackages = with pkgs.unstable; [
    libguestfs
    guestfs-tools
    virt-viewer
    virtio-win
  ];
}
