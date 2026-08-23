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
  homesTree = repoTree.homes or { };

  # Layout under homes/:
  #   homes/<system>/<user>/**.nix         -> homeConfigurations."<user>@<system>"
  #   homes/<system>/<user>@<host>/**.nix  -> homeConfigurations."<user>@<host>@<system>"
  # The directory key is also published as an alias when it identifies exactly
  # one configuration across all systems.
  keyCounts = lib.foldlAttrs (
    counts: _system: entries:
    lib.foldlAttrs (
      counts': key: _:
      counts'
      // {
        ${key} = (counts'.${key} or 0) + 1;
      }
    ) counts entries
  ) { } homesTree;

  mkHome =
    system: key:
    let
      username = builtins.head (lib.splitString "@" key);
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgsPolicy.mkPkgs system;
      extraSpecialArgs = {
        inherit
          self
          inputs
          system
          username
          myLib
          repoTree
          ;
      };
      modules = [
        repoTree.lib.inject-module-context
        repoTree.home-manager.standalone
        {
          imports =
            myLib.flattenAttrTreeToList homesTree.${system}.${key}
            ++ myLib.flattenAttrTreeToList repoTree.shared-options;
        }
      ];
    };

  homeConfigurations = lib.concatMapAttrs (
    system: entries:
    lib.concatMapAttrs (
      key: _:
      let
        configuration = mkHome system key;
      in
      {
        "${key}@${system}" = configuration;
      }
      // lib.optionalAttrs (keyCounts.${key} == 1) {
        ${key} = configuration;
      }
    ) entries
  ) homesTree;
in
{
  flakeModule = {
    # Every module contributes the platforms it needs; flake-parts merges them.
    systems = builtins.attrNames homesTree;

    flake = { inherit homeConfigurations; };

    perSystem =
      { system, ... }:
      {
        checks =
          lib.mapAttrs'
            (name: configuration: lib.nameValuePair "home-${name}" configuration.activationPackage)
            (
              lib.filterAttrs (
                _name: configuration: configuration.pkgs.stdenv.hostPlatform.system == system
              ) homeConfigurations
            );
      };
  };
}
