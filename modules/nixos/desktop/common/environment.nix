{
  config,
  ...
}:

let
  inherit (config.my.shared.catppuccin) flavor accent;
in
{
  # ── Wayland session defaults ────────────────────────────────
  # greetd (with its default source_profile=true) loads these through
  # /etc/profile before starting the selected desktop session.
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Electron apps Wayland support
    XCURSOR_THEME = "catppuccin-${flavor}-${accent}-cursors";
    XCURSOR_SIZE = "32";
  };
}
