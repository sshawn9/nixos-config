{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktops.niri.enable {
    programs.niri = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.niri;
    };
  };
}
