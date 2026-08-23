{
  lib,
  config,
  ...
}:
let
  populateTargetEtcNixosOverlay = final: prev: {
    calamares-nixos-extensions = prev.calamares-nixos-extensions.overrideAttrs (old: {
      # The only ordered pair in the tree, which is why it is also the only
      # module holding two patches: the second anchors on lines the first
      # inserts, so it must be applied after it. Keeping both in one list makes
      # that a matter of position in a list one can read, rather than a claim
      # about how two modules' overlays happen to compose.
      patches = (old.patches or [ ]) ++ [
        (final.replaceVars ./patches/stage-repository.patch {
          source = "${config.my.installer.source}";
        })
        (final.replaceVars ./patches/write-installed-flake.patch {
          mkpasswd = lib.getExe final.mkpasswd;
          target = config.my.installer.target;
        })
      ];
      patchFlags = lib.unique (lib.toList (old.patchFlags or "-p1") ++ [ "--fuzz=0" ]);
    });
  };
in
{
  config = {
    nixpkgs.overlays = [ populateTargetEtcNixosOverlay ];
  };
}
