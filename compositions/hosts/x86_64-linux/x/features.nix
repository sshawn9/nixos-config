{
  home-manager.users.star.features = {
    catppuccin.enable = true;
    git.enable = true;
    nix-ld.enable = true;
    ssh.enable = true;
    system-base.enable = true;
    terminal.enable = true;

    caddy.enable = true;
    container.enable = true;
    desktop = {
      enable = true;
      niri.enable = true;
      noctalia.enable = true;
    };
    easytier = {
      enable = true;
      client = {
        enable = true;
        configServer = "https://et-config.sshawn9.com/user";
      };
    };
    libvirt.enable = true;
    mihomo.enable = true;
    nvidia.enable = true;
    programs.enable = true;
    qbittorrent.enable = true;
    sops.enable = true;
    system-tuning.enable = true;
  };
}
