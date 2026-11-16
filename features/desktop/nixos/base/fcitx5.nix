{ config, lib, ... }:
{
  config = lib.mkIf config.features.desktop.enable {
    # Fcitx5 is managed by HM. Override GNOME's default ibus to avoid two IMEs.
    i18n.inputMethod.enable = false;
  };
}
