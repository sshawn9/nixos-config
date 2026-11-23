{
  lib,
  calamares-nixos-extensions,
  replaceVars,
  mkpasswd,
  source,
  configuration,
  offline,
}:
calamares-nixos-extensions.overrideAttrs (old: {
  patches =
    (old.patches or [ ])
    ++ [
      ./patches/target-profile.patch
      (replaceVars ./patches/install-flake.patch {
        inherit source configuration;
        mkpasswd = lib.getExe mkpasswd;
        offline = if offline then "True" else "False";
      })
    ]
    ++ lib.optional offline ./patches/offline.patch;
  patchFlags = lib.unique (lib.toList (old.patchFlags or "-p1") ++ [ "--fuzz=0" ]);
})
