{ config, ... }:
{
  # HM needs pkgs before its feature switch can be read; keep registration static.
  nixpkgs.overlays = [
    (final: prev: {
      unstable = prev.unstable.extend (
        unstableFinal: unstablePrev: {
          easytier =
            if config.features.easytier.enable then
              unstableFinal.callPackage ./package.nix { }
            else
              unstablePrev.easytier;
        }
      );

      easytier = if config.features.easytier.enable then final.unstable.easytier else prev.easytier;
    })
  ];
}
