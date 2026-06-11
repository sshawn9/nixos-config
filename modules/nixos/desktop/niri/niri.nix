{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktops.niri.enable {
    programs.niri = {
      enable = true;
      package = pkgs.unstable.niri;
    };
  };
}
