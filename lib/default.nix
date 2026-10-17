{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  loader = import ./loader.nix { inherit inputs lib; };
in
{
  inherit loader;

  moduleContext = import ./module-context.nix;

  inherit (loader)
    flattenAttrTreeToList
    loadRecursiveModulePathList
    loadRecursiveModulePathAttrs
    loadShallowModulePathList
    loadShallowModulePathAttrs
    ;
}
