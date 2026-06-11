{
  config,
  ...
}:

let
  inherit (config.my.shared.catppuccin) flavor accent;
in
{
  # ── Wayland session defaults ────────────────────────────────
  # Applies to any Wayland desktop whose login path sources /etc/profile
  # (e.g. GDM → GNOME). For compositors started directly by greetd without
  # a login shell (e.g. niri), also set these at the compositor level.
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Electron apps Wayland support
    XCURSOR_THEME = "catppuccin-${flavor}-${accent}-cursors";
    XCURSOR_SIZE = "24";
  };
}
