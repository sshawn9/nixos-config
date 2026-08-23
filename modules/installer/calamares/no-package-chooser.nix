{
  lib,
  ...
}:
let
  noPackageChooserOverlay = _final: prev: {
    calamares-nixos-extensions = prev.calamares-nixos-extensions.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ./patches/packagechooser-remove-from-sequence.patch
        ./patches/packagechooser-default-globalstorage-key.patch
      ];
      patchFlags = lib.unique (lib.toList (old.patchFlags or "-p1") ++ [ "--fuzz=0" ]);
    });
  };
in
{
  nixpkgs.overlays = [ noPackageChooserOverlay ];
}
