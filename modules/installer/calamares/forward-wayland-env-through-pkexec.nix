_:

let
  forwardWaylandEnvOverlay = _final: prev: {
    calamares-nixos = prev.calamares-nixos.overrideAttrs (old: {
      # The desktop entry starts Calamares as root through pkexec, and pkexec
      # replaces the environment with a whitelist. `allow_gui` on the polkit
      # action keeps DISPLAY and XAUTHORITY; there is no Wayland equivalent, so
      # WAYLAND_DISPLAY is dropped and Qt, seeing no Wayland display, falls back
      # to the xcb plugin. GNOME hands XWayland an integer scale and expects X
      # clients to scale themselves from Xft.dpi; Qt does not, so the wizard
      # draws at 1x next to a desktop that is not, and comes out visibly small.
      #
      # argv survives pkexec even though the environment does not, so the shell
      # that runs as the session user passes the two values along as arguments.
      # Qt then loads the wayland plugin and takes its scale from the compositor,
      # fractional scales included, with no DPI arithmetic anywhere.
      postInstall = (old.postInstall or "") + ''
        substituteInPlace $out/share/applications/calamares.desktop \
          --replace-fail 'Exec=sh -c "pkexec calamares"' \
            "Exec=sh -c 'exec pkexec env XDG_RUNTIME_DIR=\"\$XDG_RUNTIME_DIR\" WAYLAND_DISPLAY=\"\$WAYLAND_DISPLAY\" calamares'"
      '';
    });
  };
in
{
  config = {
    nixpkgs.overlays = [ forwardWaylandEnvOverlay ];
  };
}
