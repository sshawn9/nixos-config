{
  lib,
  ...
}:
let
  installFromFlakeOverlay = _final: prev: {
    calamares-nixos-extensions = prev.calamares-nixos-extensions.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./patches/nixos-install-cmd-install-from-flake.patch ];
      patchFlags = lib.unique (lib.toList (old.patchFlags or "-p1") ++ [ "--fuzz=0" ]);
    });
  };
in
{
  config = {
    nixpkgs.overlays = [ installFromFlakeOverlay ];
  };
}
