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
      # 在 DNS 服务商处将设备接入域名的 A/AAAA 记录指向后端所在服务器的公网 IP。
      # 使用仅 DNS 模式，不经 HTTP/CDN 代理。
      # UDP/TCP/原生 WS 按连接地址的协议和端口直连服务器。
      # wssDomain 仅配置 Caddy 的 WSS 入口（443 → WS 22022），不会创建或修改 DNS 记录。
      # 下列地址中的示例域名和 DEVICE_TOKEN 均需替换为实际值。
      backend = {
        udp = {
          # udp://et-config.example.com:22020/DEVICE_TOKEN
          enable = true;
          apiDomain = "et-api-udp.sshawn9.com";
        };
        tcp = {
          # tcp://et-config.example.com:22021/DEVICE_TOKEN
          enable = true;
          apiDomain = "et-api-tcp.sshawn9.com";
        };
        ws = {
          # WS：ws://et-config.example.com:22022/DEVICE_TOKEN
          # WSS：wss://et-config.example.com/DEVICE_TOKEN
          enable = true;
          apiDomain = "et-api-ws.sshawn9.com";
          wssDomain = "et-config.sshawn9.com";
        };
      };
      frontend = {
        default = {
          type = "tcp";
          domain = "et.sshawn9.com";
        };
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
