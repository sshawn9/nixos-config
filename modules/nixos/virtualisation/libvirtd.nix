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
  networking.firewall.extraCommands = lib.mkIf config.virtualisation.libvirtd.enable ''
    iptables -A nixos-fw -i virbr0 \
      -m conntrack --ctstate DNAT \
      -j nixos-fw-accept
  '';

  # networking.firewall.trustedInterfaces = [ "virbr0" ];

  services.cockpit = {
    enable = lib.mkDefault false;
    package = pkgs.unstable.cockpit;
    port = lib.mkDefault 9091;
    plugins = [ pkgs.unstable.cockpit-machines ];
    openFirewall = lib.mkDefault true;
  };

  users.users = {
    ${username}.extraGroups = lib.optionals config.virtualisation.libvirtd.enable [
      "kvm"
      "libvirtd"
    ];

    libvirtdbus =
      lib.mkIf (config.virtualisation.libvirtd.enable && config.virtualisation.libvirtd.dbus.enable)
        {
          extraGroups = [ "libvirtd" ];
        };
  };

  virtualisation = {
    libvirtd = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.libvirt;

      dbus = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.libvirt-dbus;
      };

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

    spiceUSBRedirection.enable = lib.mkDefault config.virtualisation.libvirtd.enable;
  };

  programs = {
    virt-manager = {
      enable = lib.mkDefault config.virtualisation.libvirtd.enable;
      package = lib.mkDefault pkgs.unstable.virt-manager;
    };
  };

  environment.systemPackages = lib.mkIf config.virtualisation.libvirtd.enable [
    pkgs.unstable.freerdp
  ];

  systemd.tmpfiles.rules = lib.mkIf config.virtualisation.libvirtd.enable [
    "L+ /var/lib/libvirt/images/virtio-win.iso - - - - ${pkgs.virtio-win.src}"
  ];

  # environment.systemPackages = with pkgs.unstable; [
  #   libguestfs
  #   guestfs-tools
  #   virt-viewer
  #   virtio-win
  # ];
}
