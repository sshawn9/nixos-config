{
  self,
  inputs,
  lib,
  myLib,
  repoTree,
  nixpkgsPolicy,
  ...
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

      hostnameCounts = lib.foldlAttrs (
        counts: _system: hosts:
        lib.foldlAttrs (
          counts': hostname: _:
          counts'
          // {
            ${hostname} = (counts'.${hostname} or 0) + 1;
          }
        ) counts hosts
      ) { } matchingSystems;
    in
    lib.concatMapAttrs (
      system: hosts:
      lib.concatMapAttrs (
        hostname: _:
        let
          configuration = mkSystem builder system hostname;
        in
        # The canonical name, spellable by anyone who knows the platform and the
        # directory, without knowing what else exists. The bare directory name is
        # the same configuration under a second key, kept because nixos-rebuild
        # looks a configuration up by the machine's hostname; it is dropped when
        # two platforms share a directory name, since it could not say which.
        {
          "${hostname}@${system}" = configuration;
        }
        // lib.optionalAttrs (hostnameCounts.${hostname} == 1) {
          ${hostname} = configuration;
        }
      ) hosts
    ) matchingSystems;

  nixosConfigurations = configurationsFor (lib.hasSuffix "linux") inputs.nixpkgs.lib.nixosSystem;
  darwinConfigurations = configurationsFor (lib.hasSuffix "darwin") inputs.nix-darwin.lib.darwinSystem;
in
{
  inherit systemsTree;

  inherit nixosConfigurations darwinConfigurations;

  flakeModule = {
    # Every module contributes the platforms it needs; flake-parts merges them.
    systems = builtins.attrNames systemsTree;

    flake = { inherit nixosConfigurations darwinConfigurations; };

    perSystem =
      { system, ... }:
      {
        # Standard flake outputs are evaluated by `nix flake check` already;
        # explicit checks additionally make every system closure buildable.
        checks =
          lib.mapAttrs'
            (name: configuration: lib.nameValuePair "nixos-${name}" configuration.config.system.build.toplevel)
            (
              lib.filterAttrs (
                _name: configuration: configuration.pkgs.stdenv.hostPlatform.system == system
              ) nixosConfigurations
            )
          // lib.mapAttrs' (name: configuration: lib.nameValuePair "darwin-${name}" configuration.system) (
            lib.filterAttrs (
              _name: configuration: configuration.pkgs.stdenv.hostPlatform.system == system
            ) darwinConfigurations
          );
      };
  };
}
