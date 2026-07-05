{ lib, ... }:

{
  services.grafana = {
    enable = lib.mkDefault false;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
      };
      security.secret_key = "7f92c41a6de84b10b83f5e209d6748c9d7a35f861eb24c7792a105c83f46e8bd";
    };
  };
}
