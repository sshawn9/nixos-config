{ pkgs, ... }:

{
  # XMODIFIERS / QT_IM_MODULE / GTK_IM_MODULE are set by the upstream
  # i18n.inputMethod.fcitx5 module via `environment.variables`. We deliberately
  # do NOT mirror them into `environment.sessionVariables` here:
  #   - pam_env parses `XMODIFIERS=@im=fcitx` and warns "Expandable variables
  #     must be wrapped in {}" because it interprets `@` as the start of a
  #     `@{VAR}` substitution. The value is still set correctly, but the
  #     warning shows up on every PAM session (including greetd login).
  #   - With waylandFrontend = true, Wayland-native apps speak the wayland-im
  #     protocol and do not consult XMODIFIERS at all.

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;

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
    };
  };

  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
  ];
}
