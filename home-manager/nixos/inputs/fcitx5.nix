{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.my.paths.local)
    xdgConfigLayeredSource
    xdgDataLayeredSource
    ;

  rimeSyncDir = "${config.home.homeDirectory}/ghq/github.com/sshawn9/rime-sync";

  catppuccinTheme = "catppuccin-${config.catppuccin.fcitx5.flavor}-${config.catppuccin.fcitx5.accent}";
in
{
  my.packages.adwaita-icon-theme = lib.mkDefault true;

  catppuccin.fcitx5 = {
    enable = lib.mkDefault true;
    enableRounded = true;
  };

  i18n.inputMethod = {
    enable = lib.mkDefault true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;

      # XDG autostart already starts fcitx5 in this session, so the systemd
      # user service would only duplicate it.
      systemd.enable = false;

      # The Home Manager module leaves XMODIFIERS unset, but X11 apps under
      # Xwayland still need it for XIM. With waylandFrontend = true,
      # Wayland-native apps speak the wayland-im protocol and do not consult
      # XMODIFIERS at all. Home Manager session variables do not go through
      # pam_env, so the `@` here does not trigger its "Expandable variables
      # must be wrapped in {}" warning on every PAM session.
      sessionVariables.XMODIFIERS = "@im=fcitx";

      addons = with pkgs; [
        fcitx5-gtk
        libsForQt5.fcitx5-qt
        kdePackages.fcitx5-qt
        (fcitx5-rime.override {
          rimeDataPkgs = [
            unstable.rime-ice
            rime-data
          ];
        })
        fcitx5-material-color
      ];

      # fcitx5 reads only the first classicui.conf it finds, and the catppuccin
      # port writes Theme into this one, so the other classic UI options live
      # here as well.
      settings.addons.classicui.globalSection = {
        # Vertical Candidate List
        "Vertical Candidate List" = false;
        # Use mouse wheel to go to prev or next page
        WheelForPaging = true;
        # Font
        Font = ''"Sans Serif 16"'';
        # Menu Font
        MenuFont = ''"Sans Serif 16"'';
        # Tray Font
        TrayFont = ''"Sans Serif 16"'';
        # Tray Label Outline Color
        TrayOutlineColor = "#000000";
        # Tray Label Text Color
        TrayTextColor = "#ffffff";
        # Prefer Text Icon
        PreferTextIcon = false;
        # Show Layout Name In Icon
        ShowLayoutNameInIcon = true;
        # Use input method language to display text
        UseInputMethodLanguageToDisplayText = true;
        # Follow system light/dark color scheme
        UseDarkTheme = false;
        # Follow system accent color if it is supported by theme and desktop
        UseAccentColor = false;
        # Use Per Screen DPI on X11
        PerScreenDPI = false;
        # Force font DPI on Wayland
        ForceWaylandDPI = 0;
        # Enable fractional scale under Wayland
        EnableFractionalScale = true;
      };
    };
  };

  xdg = {
    configFile = {
      # The fcitx5 module links its generated files as a single directory.
      # Link them one by one instead, so they coexist with the dotfiles below
      # and fcitx5 can still write runtime files such as conf/cached_layouts.
      "fcitx5".recursive = true;

      "fcitx5/config".source = xdgConfigLayeredSource "fcitx5/config";
      "fcitx5/profile".source = xdgConfigLayeredSource "fcitx5/profile";
      "fcitx5/conf/rime.conf".source = xdgConfigLayeredSource "fcitx5/conf/rime.conf";
    };

    dataFile = {
      # Overrides on top of the installed catppuccin theme; the directory name
      # must match the active theme.
      "fcitx5/themes/${catppuccinTheme}/theme.conf".source =
        xdgDataLayeredSource "fcitx5/themes/catppuccin/theme.conf";
      "fcitx5/rime/default.custom.yaml".source = xdgDataLayeredSource "fcitx5/rime/default.custom.yaml";
      "fcitx5/rime/rime_ice.custom.yaml".source = xdgDataLayeredSource "fcitx5/rime/rime_ice.custom.yaml";
      "fcitx5/rime/fcitx5.custom.yaml".source = xdgDataLayeredSource "fcitx5/rime/fcitx5.custom.yaml";
    };
  };

  home.activation.patchRimeInstallation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    rime_dir="$HOME/.local/share/fcitx5/rime"
    installation="$rime_dir/installation.yaml"

    install -d "$rime_dir"
    install -d "${rimeSyncDir}"
    test -e "$installation" || install -m 600 /dev/null "$installation"

    tmp="$(mktemp)"
    cp "$installation" "$tmp"

    ${pkgs.yq-go}/bin/yq -i '
      .installation_id = "star-nixos-rime-sync" |
      .sync_dir = "${rimeSyncDir}"
    ' "$tmp"

    if ! cmp -s "$tmp" "$installation"; then
      cp "$tmp" "$installation"
    fi

    rm -f "$tmp"
  '';
}
