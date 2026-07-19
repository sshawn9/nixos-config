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
    let
      matchingSystems = lib.filterAttrs (system: _: systemPredicate system) systemsTree;

      hostnameSystems = lib.foldlAttrs (
        acc: system: hosts:
        lib.foldlAttrs (
          acc': hostname: _:
          acc'
          // {
            ${hostname} = (acc'.${hostname} or [ ]) ++ [ system ];
          }
        ) acc hosts
      ) { } matchingSystems;
    in
    lib.concatMapAttrs (
      system: hosts:
      lib.mapAttrs' (
        hostname: _:
        let
          outputName =
            if builtins.length hostnameSystems.${hostname} == 1 then hostname else "${hostname}@${system}";
        in
        lib.nameValuePair outputName (mkSystem builder system hostname)
      ) hosts
    ) matchingSystems;
in
{
  inherit systemsTree;
  supportedSystems = builtins.attrNames systemsTree;
  nixosConfigurations = configurationsFor (lib.hasSuffix "linux") inputs.nixpkgs.lib.nixosSystem;
  darwinConfigurations = configurationsFor (lib.hasSuffix "darwin") inputs.nix-darwin.lib.darwinSystem;
}
