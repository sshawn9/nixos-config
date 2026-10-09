{
  lib,
  system,
  config,
  ...
}:

lib.optionalAttrs (lib.hasSuffix "linux" system) {
  options.my.shared.desktop = {
    active = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "gnome"
          "niri"
          "hyprland"
        ]
      );
      description = "Active desktop environments for this host.";
    };

    niri.enable = lib.mkEnableOption "Niri" // {
      default = lib.elem "niri" config.my.shared.desktop.active;
    };

    gnome.enable = lib.mkEnableOption "GNOME" // {
      default = lib.elem "gnome" config.my.shared.desktop.active;
    };

    hyprland.enable = lib.mkEnableOption "Hyprland" // {
      default = lib.elem "hyprland" config.my.shared.desktop.active;
    };

    noctalia.enable = lib.mkEnableOption "Noctalia";

    dms.enable = lib.mkEnableOption "Dank Material Shell";
  };
}
