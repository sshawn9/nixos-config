{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  loader = import ./loader.nix { inherit inputs lib; };
  moduleContextLib = import ./module-context.nix { };
in
{
  inherit loader;

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
}
