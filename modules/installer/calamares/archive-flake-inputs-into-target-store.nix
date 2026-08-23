{
  lib,
  ...
}:
let
  archiveFlakeInputsIntoTargetStoreOverlay = _final: prev: {
    calamares-nixos-extensions = prev.calamares-nixos-extensions.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./patches/archive-flake-inputs-into-target-store.patch ];
      patchFlags = lib.unique (lib.toList (old.patchFlags or "-p1") ++ [ "--fuzz=0" ]);
    });
  };
in
{
  # Not tied to `offline.enable`, unlike no-internet-check.nix: the target is a
  # second store whether or not there is a network. Offline the copy is the only
  # way the inputs reach it at all; online it saves the download.
  config = {
    nixpkgs.overlays = [ archiveFlakeInputsIntoTargetStoreOverlay ];
  };
}
