{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  loader = import ./loader.nix {
    inherit lib;
    haumea = inputs.haumea.lib;
  };
  moduleContext = import ./module-context.nix;
in
{
  inherit loader;

  inherit (loader)
    flattenAttrTreeToList
    loadRecursiveModulePathList
    loadRecursiveModulePathAttrs
    loadShallowModulePathList
    loadShallowModulePathAttrs
    ;

  inherit (moduleContext)
    inHomeManager
    inEmbeddedHM
    inStandaloneHM
    inNixOSProper
    inDarwinProper
    inNixOSSystem
    inDarwinSystem
    ;
}
