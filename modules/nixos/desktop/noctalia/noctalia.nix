{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktop.noctalia.enable {
    programs.noctalia = {
      enable = lib.mkDefault true;
      package = pkgs.unstable.noctalia;
      systemd.enable = lib.mkDefault true;
      recommendedServices.enable = lib.mkDefault true;
    };
  };
}
