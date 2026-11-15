{ inputs }:
system:
let
  config = {
    allowUnfree = true;
  };
in
import inputs.nixpkgs {
  inherit system config;
  overlays = [
    (_: prev: {
      stable = import inputs.nixpkgs-stable {
        inherit (prev.stdenv.hostPlatform) system;
        inherit config;
      };

      unstable = import inputs.nixpkgs-unstable {
        inherit (prev.stdenv.hostPlatform) system;
        inherit config;
      };
    })
  ];
}
