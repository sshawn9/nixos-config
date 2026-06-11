{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  loader = import ./loader.nix { inherit inputs lib; };
  mkPackages = import ./mk-packages.nix { inherit lib; };
  moduleContextLib = import ./module-context.nix { };
in
{
  inherit
    loader
    mkPackages
    ;

  inherit (moduleContextLib)
    inHomeManager
    inEmbeddedHM
    inStandaloneHM
    inNixOSProper
    inDarwinProper
    inNixOSSystem
    inDarwinSystem
    ;

  inherit (loader)
    flattenAttrTreeToList
    loadRecursiveModulePathList
    loadRecursiveModulePathAttrs
    loadShallowModulePathList
    loadShallowModulePathAttrs
    ;

  inherit (mkPackages)
    mkHomePackages
    mkSystemPackages
    ;
}
