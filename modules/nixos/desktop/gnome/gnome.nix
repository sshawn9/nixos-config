{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktops.gnome.enable {
    services = {
      desktopManager.gnome.enable = lib.mkDefault true;
      gnome = {
        core-developer-tools.enable = lib.mkDefault false;
        games.enable = lib.mkDefault false;
      };
    };
    environment = {
      # greetd removes XDG_SESSION_CLASS after PAM. Restore it for GNOME so
      # gnome-session imports it into the user manager, where LocalSearch's
      # upstream service checks ConditionEnvironment=XDG_SESSION_CLASS=user.
      extraInit = ''
        if [ -z "''${XDG_SESSION_CLASS-}" ]; then
          case ":''${XDG_CURRENT_DESKTOP-}:" in
            *:GNOME:*) export XDG_SESSION_CLASS=user ;;
          esac
        fi
      '';

      gnome.excludePackages = with pkgs; [
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

      systemPackages = with pkgs; [
        unstable.gnomeExtensions.kimpanel
        unstable.gnomeExtensions.vitals
        unstable.gnomeExtensions.caffeine
        unstable.gnomeExtensions.dash-to-panel
      ];
    };
  };
}
