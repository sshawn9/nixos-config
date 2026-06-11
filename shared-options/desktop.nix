{
  lib,
  system,
  config,
  ...
}:

lib.optionalAttrs (lib.hasSuffix "linux" system) {
  options.my.shared.desktops = {
    active = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "gnome"
          "niri"
        ]
      );
      description = "Active desktop environments for this host.";
    };

    niri.enable = lib.mkEnableOption "Niri" // {
      default = lib.elem "niri" config.my.shared.desktops.active;
    };

    gnome.enable = lib.mkEnableOption "GNOME" // {
      default = lib.elem "gnome" config.my.shared.desktops.active;
    };
  };
}
