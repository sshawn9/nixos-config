{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktop.dms.enable {
    programs.dms-shell = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.dms-shell;
      quickshell.package = lib.mkDefault pkgs.unstable.quickshell;
      systemd.enable = lib.mkDefault true;
    };

    programs.dsearch = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.dsearch;
      systemd.enable = lib.mkDefault true;
    };
  };
}
