_:

{
  # fcitx5 itself, its addons, and its configuration live in Home Manager:
  # home-manager/nixos/inputs/fcitx5.nix.

  # GNOME enables ibus as the system input method by default. Left on, ibus
  # would run alongside fcitx5 in every session:
  #   - QT_IM_MODULE=ibus and XMODIFIERS=@im=ibus are set system-wide; Home
  #     Manager only overrides XMODIFIERS, so Qt apps would still go to ibus.
  #   - Its XDG autostart entry starts ibus-daemon in non-GNOME sessions such
  #     as niri, and GNOME starts ibus itself.
  # A plain value is enough to override GNOME's mkDefault, and a conflicting
  # non-default definition elsewhere still fails evaluation instead of being
  # silently overridden.
  i18n.inputMethod.enable = false;
}
