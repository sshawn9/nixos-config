{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.features.desktop.enable && config.features.desktop.gnome.enable) {
    services.desktopManager.gnome.enable = lib.mkDefault true;

    services.gnome = {
      core-developer-tools.enable = lib.mkDefault false;
      games.enable = lib.mkDefault false;
    };

    environment = {
      # Restore the session class before GNOME imports its user-manager environment.
      extraInit = ''
        if [ -z "''${XDG_SESSION_CLASS-}" ]; then
          case ":''${XDG_CURRENT_DESKTOP-}:" in
            *:GNOME:*) export XDG_SESSION_CLASS=user ;;
          esac
        fi
      '';

      gnome.excludePackages = with pkgs.unstable; [
        gst-thumbnailers
        gnome-tour
        gnome-music
        epiphany
        geary
        totem
        yelp
        gnome-contacts
        gnome-maps
        simple-scan
      ];

      systemPackages = with pkgs.unstable.gnomeExtensions; [
        kimpanel
        vitals
        caffeine
        dash-to-panel
      ];
    };
  };
}
