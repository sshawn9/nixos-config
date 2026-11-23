{
  symlinkJoin,
  makeWrapper,
  calamares,
  extensions,
}:
let
  # Keep the compiled application independent of the selected target and source
  # snapshot. Changing either only rebuilds the configuration and its wrapper.
  application = calamares.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./patches/export-root-password.patch ];
  });
in
symlinkJoin {
  name = "calamares-installer";
  paths = [ application ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/calamares \
      --prefix XDG_CONFIG_DIRS : ${extensions}/etc \
      --prefix XDG_DATA_DIRS : ${extensions}/share \
      --add-flags --xdg-config
    cp --remove-destination ${application}/share/applications/calamares.desktop $out/share/applications/calamares.desktop
    substituteInPlace $out/share/applications/calamares.desktop \
      --replace-fail 'Exec=sh -c "pkexec calamares"' \
        "Exec=sh -c 'exec pkexec env XDG_RUNTIME_DIR=\"\$XDG_RUNTIME_DIR\" WAYLAND_DISPLAY=\"\$WAYLAND_DISPLAY\" $out/bin/calamares'"
  '';
  passthru = { inherit application extensions; };
  inherit (application) meta;
}
