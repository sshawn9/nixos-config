{
  self,
  inputs,
  lib,
  myLib,
  repoTree,
  nixpkgsPolicy,
}:
let
  # Machines that only exist once an installer fills them in, kept in their own
  # tree beside systems/. Which tree a host lives in is the whole definition of
  # whether a medium may install it: no host declares it, no medium declares it,
  # so the two can never disagree about it.
  installerSystemsTree = repoTree.installer-systems or { };

  # A target is not a configuration, it is a configuration missing everything
  # only the installer can know. The argument is mandatory, so a system that was
  # never told what it is being installed onto is not a value that exists.
  mkInstalledSystem =
    system: hostname:
    generated: # modules the installer wrote, already in their final form
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      # `hostname` is the directory key, not a machine name, so it is not passed
      # on as a module argument: it would land in shared-options/hostname.nix as
      # the default for `my.shared.hostname`, and a machine silently named after
      # the template it was built from is the failure this tree exists to avoid.
      # Generated modules that forget the name now fail instead.
      specialArgs = {
        inherit
          self
          inputs
          system
          myLib
          repoTree
          ;
      };
      modules = [
        repoTree.modules.default
        repoTree.home-manager.embedded
        repoTree.lib.inject-module-context
        {
          # Nothing is unpacked or re-derived here: the installer writes modules,
          # and this appends them. `hostname` above stays the directory name it
          # is for a host under systems/, which is only the default those modules
          # replace with the name the machine was actually given.
          imports =
            myLib.flattenAttrTreeToList installerSystemsTree.${system}.${hostname}
            ++ myLib.flattenAttrTreeToList repoTree.shared-options
            ++ generated;

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

  # Published so the flake the installer writes onto the target can call it, and
  # so a medium can prebuild the closure it has to carry. Keyed the way hosts
  # are: from the installed machine's point of view this is what it is.
  installedSystems = lib.foldlAttrs (
    acc: system: hosts:
    acc
    // lib.mapAttrs' (
      hostname: _: lib.nameValuePair "${hostname}@${system}" (mkInstalledSystem system hostname)
    ) hosts
  ) { } installerSystemsTree;
in
{
  flakeModule = {
    flake = { inherit installedSystems; };
  };
}
