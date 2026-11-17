{ lib, ... }:
{
  features = {
    caddy.enable = lib.mkDefault true;
    catppuccin.enable = lib.mkDefault true;
    container.enable = lib.mkDefault true;
    desktop.enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
    libvirt.enable = lib.mkDefault true;
    mihomo.enable = lib.mkDefault true;
    nix-ld.enable = lib.mkDefault true;
    nvidia.enable = lib.mkDefault true;
    programs.enable = lib.mkDefault true;
    programs-cli.enable = lib.mkDefault true;
    qbittorrent.enable = lib.mkDefault true;
    scheduling.enable = lib.mkDefault true;
    sops.enable = lib.mkDefault true;
    ssh.enable = lib.mkDefault true;
    system-base.enable = lib.mkDefault true;
    terminal.enable = lib.mkDefault true;
    user-environment.enable = lib.mkDefault true;
  };
}
