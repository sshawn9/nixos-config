# sudo virsh net-start default
# sudo virsh net-autostart default

{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.my.shared) username;
in
{
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -i virbr0 \
      -m conntrack --ctstate DNAT \
      -j nixos-fw-accept
  '';

  # networking.firewall.trustedInterfaces = [ "virbr0" ];

  virtualisation = {
    libvirtd = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.libvirt;

      qemu = {
        package = lib.mkDefault pkgs.unstable.qemu_kvm;
        runAsRoot = true;
        vhostUserPackages = [ pkgs.unstable.virtiofsd ];

        swtpm = {
          enable = lib.mkDefault true;
          package = lib.mkDefault pkgs.unstable.swtpm;
        };
      };
    };

    spiceUSBRedirection.enable = lib.mkDefault true;
  };

  programs = {
    dconf.enable = lib.mkDefault true;
    virt-manager = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.virt-manager;
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
