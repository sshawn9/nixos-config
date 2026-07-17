{
  self,
  inputs,
  lib,
  myLib,
  repoTree,
  nixpkgsPolicy,
}:
let
  systemsTree = repoTree.systems or { };

  mkSystem =
    builder: system: hostname:
    builder {
      inherit system;
      specialArgs = {
        inherit
          self
          inputs
          system
          hostname
          myLib
          repoTree
          ;
      };
      modules = [
        repoTree.modules.default
        repoTree.home-manager.embedded
        repoTree.lib.inject-module-context
        {
          imports =
            myLib.flattenAttrTreeToList systemsTree.${system}.${hostname}
            ++ myLib.flattenAttrTreeToList repoTree.shared-options;
          nixpkgs.pkgs = nixpkgsPolicy.mkPkgs system;
          home-manager.sharedModules = [
            repoTree.lib.inject-module-context
            {
              imports = myLib.flattenAttrTreeToList repoTree.shared-options;
            }
          ];
        }
      ];
    };

  configurationsFor =
    systemPredicate: builder:
    lib.concatMapAttrs (
      system: hosts:
      if systemPredicate system then
        lib.mapAttrs (hostname: _: mkSystem builder system hostname) hosts
      else
        { }
    ) systemsTree;
in
{
  inherit systemsTree;
  supportedSystems = builtins.attrNames systemsTree;
  nixosConfigurations = configurationsFor (lib.hasSuffix "linux") inputs.nixpkgs.lib.nixosSystem;
  darwinConfigurations = configurationsFor (lib.hasSuffix "darwin") inputs.nix-darwin.lib.darwinSystem;
}
