{
  lib,
  config,
  ...
}:
let
  noInternetCheckOverlay = _final: prev: {
    calamares-nixos-extensions = prev.calamares-nixos-extensions.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./patches/no-internet-check.patch ];
      patchFlags = lib.unique (lib.toList (old.patchFlags or "-p1") ++ [ "--fuzz=0" ]);
    });
  };
in
{
  config = lib.mkIf config.my.installer.offline.enable {
    nixpkgs.overlays = [ noInternetCheckOverlay ];
  };
}
