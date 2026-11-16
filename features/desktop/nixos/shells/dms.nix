{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.features.desktop.enable && config.features.desktop.dms.enable) {
    programs.dux-shell = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.dux-shell;
      quickshell.package = lib.mkDefault pkgs.unstable.quickshell;
      systemd.enable = lib.mkDefault true;
    };

    programs.dux-search = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.dux-search;
      systemd.enable = lib.mkDefault true;
    };
  };
}
