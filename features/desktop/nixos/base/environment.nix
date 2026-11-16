{ config, lib, ... }:
let
  theme = config.features.catppuccin;
in
{
  config = lib.mkIf config.features.desktop.enable {
    environment.sessionVariables = {
      NIXOS_OZONE_WL = lib.mkDefault "1";
      XCURSOR_THEME = lib.mkIf theme.enable (
        lib.mkDefault "catppuccin-${theme.flavor}-${theme.accent}-cursors"
      );
      XCURSOR_SIZE = lib.mkDefault (toString config.features.desktop.cursor.size);
    };
  };
}
