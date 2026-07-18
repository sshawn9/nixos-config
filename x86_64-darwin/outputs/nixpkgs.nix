{ inputs }:
let
  nixpkgsConfig = {
    allowUnfree = true;
  };

  nixpkgsOverlays = [
    (_: prev: {
      stable = import inputs.nixpkgs-stable {
        inherit (prev.stdenv.hostPlatform) system;
        config = nixpkgsConfig;
      };

      unstable = import inputs.nixpkgs-unstable {
        inherit (prev.stdenv.hostPlatform) system;
        config = nixpkgsConfig;
      };
    })
  ];

  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system;
      config = nixpkgsConfig;
      overlays = nixpkgsOverlays;
    };

  flakeModule = {
    perSystem =
      { system, ... }:
      {
        _module.args.pkgs = mkPkgs system;
      };
  };
in
{
  inherit
    mkPkgs
    flakeModule
    ;
}
