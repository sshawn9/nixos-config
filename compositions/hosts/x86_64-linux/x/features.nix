{
  home-manager.users.star.features = {
    catppuccin.enable = true;
    git.enable = true;
    nix-ld.enable = true;
    programs-cli.enable = true;
    ssh.enable = true;
    system-base.enable = true;
    terminal.enable = true;

    cachyos-kernel.enable = true;
    caddy.enable = true;
    container.enable = true;
    desktop.enable = true;
    libvirt.enable = true;
    mihomo.enable = true;
    nvidia.enable = true;
    programs.enable = true;
    qbittorrent.enable = true;
    scheduling.enable = true;
    sops.enable = true;

    desktop = {
      niri.enable = true;
      noctalia.enable = true;
    };
  };
}
