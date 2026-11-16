{ lib, ... }:
{
  options.features.desktop = {
    enable = lib.mkEnableOption "desktop integration";

    niri.enable = lib.mkEnableOption "Niri";
    gnome.enable = lib.mkEnableOption "GNOME";
    hyprland.enable = lib.mkEnableOption "Hyprland";
    noctalia.enable = lib.mkEnableOption "Noctalia";
    dms.enable = lib.mkEnableOption "DMS (Dux Shell)";

    cursor.size = lib.mkOption {
      type = lib.types.ints.positive;
      default = 32;
    };
  };
}
