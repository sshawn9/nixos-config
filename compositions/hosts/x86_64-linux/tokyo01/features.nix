{
  home-manager.users.star.features = {
    catppuccin.enable = true;
    git.enable = true;
    nix-ld.enable = true;
    programs.enable = true;
    ssh.enable = true;
    system-base.enable = true;
    terminal.enable = true;

    caddy.enable = true;
    easytier = {
      enable = true;
      relay.enable = true;
      backend = {
        default = {
          type = "tcp";
          apiDomain = "et-api.sshawn9.com";
          configDomain = "et-config.sshawn9.com";
        };
        udp = {
          enable = true;
          apiDomain = "et-api-udp.sshawn9.com";
        };
        tcp = {
          enable = true;
          apiDomain = "et-api-tcp.sshawn9.com";
        };
        ws = {
          enable = true;
          apiDomain = "et-api-ws.sshawn9.com";
        };
      };
      frontend = {
        default.domain = "et.sshawn9.com";
        udp = {
          enable = true;
          domain = "et-udp.sshawn9.com";
        };
        tcp = {
          enable = true;
          domain = "et-tcp.sshawn9.com";
        };
        ws = {
          enable = true;
          domain = "et-ws.sshawn9.com";
        };
      };
    };
    sops.enable = true;
    system-tuning.enable = true;
  };
}
