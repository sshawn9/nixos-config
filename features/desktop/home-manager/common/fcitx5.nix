{
  config,
  lib,
  pkgs,
  ...
}:
let
  im = config.i18n.inputMethod;
  enabled = im.enable && im.type == "fcitx5";
  inherit (config.lib.fileSources.local) xdgConfig xdgData;
  catppuccinTheme = "catppuccin-${config.catppuccin.fcitx5.flavor}-${config.catppuccin.fcitx5.accent}";
in
{
  config = lib.mkIf config.features.desktop.enable {
    i18n.inputMethod = {
      enable = lib.mkDefault true;
      type = lib.mkDefault "fcitx5";
      fcitx5 = {
        fcitx5-with-addons = lib.mkDefault pkgs.unstable.kdePackages.fcitx5-with-addons;
        waylandFrontend = lib.mkDefault true;
        # XDG autostart already starts Fcitx5; avoid a second instance.
        systemd.enable = lib.mkDefault false;
        sessionVariables = {
          GLFW_IM_MODULE = lib.mkDefault "ibus";
          SDL_IM_MODULE = lib.mkDefault "fcitx";
          XMODIFIERS = lib.mkDefault "@im=fcitx";
        };
        addons = with pkgs.unstable; [
          fcitx5-gtk
          libsForQt5.fcitx5-qt
          kdePackages.fcitx5-qt
          (fcitx5-rime.override {
            rimeDataPkgs = [
              rime-ice
              rime-data
            ];
          })
          fcitx5-material-color
        ];
        settings.addons.classicui.globalSection = lib.mapAttrs (_: lib.mkDefault) {
          "Vertical Candidate List" = false;
          WheelForPaging = true;
          Font = ''"Sans Serif 16"'';
          MenuFont = ''"Sans Serif 16"'';
          TrayFont = ''"Sans Serif 16"'';
          TrayOutlineColor = "#000000";
          TrayTextColor = "#ffffff";
          PreferTextIcon = false;
          ShowLayoutNameInIcon = true;
          UseInputMethodLanguageToDisplayText = true;
          UseDarkTheme = false;
          UseAccentColor = false;
          PerScreenDPI = false;
          ForceWaylandDPI = 0;
          EnableFractionalScale = true;
        };
      };
    };

    package.adwaita-icon-theme = lib.mkIf enabled (lib.mkDefault true);

    catppuccin.fcitx5 = lib.mkIf enabled {
      enable = lib.mkDefault true;
      enableRounded = lib.mkDefault true;
    };

    xdg = lib.mkIf enabled {
      configFile = {
        # Keep generated settings and repository files alongside Fcitx5's writable cache.
        "fcitx5".recursive = true;
        "fcitx5/config" = xdgConfig.link "fcitx5/config";
        "fcitx5/profile" = xdgConfig.link "fcitx5/profile";
        "fcitx5/conf/rime.conf" = xdgConfig.link "fcitx5/conf/rime.conf";
      };
      dataFile = {
        "fcitx5/themes/${catppuccinTheme}/theme.conf" = lib.mkIf (
          config.catppuccin.enable && config.catppuccin.fcitx5.enable
        ) (xdgData.link "fcitx5/themes/catppuccin/theme.conf");
        "fcitx5/rime/default.custom.yaml" = xdgData.link "fcitx5/rime/default.custom.yaml";
        "fcitx5/rime/rime_ice.custom.yaml" = xdgData.link "fcitx5/rime/rime_ice.custom.yaml";
        "fcitx5/rime/fcitx5.custom.yaml" = xdgData.link "fcitx5/rime/fcitx5.custom.yaml";
      };
    };
  };
}
