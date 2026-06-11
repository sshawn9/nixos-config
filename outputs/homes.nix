{
  self,
  inputs,
  lib,
  myLib,
  repoTree,
  nixpkgsPolicy,
}:
let
  homesTree = repoTree.homes or { };

  # Layout under homes/:
  #   homes/<system>/<user>/**.nix         -> homeConfigurations."<user>@<system>"
  #   homes/<system>/<user>@<host>/**.nix  -> homeConfigurations."<user>@<host>"
  # Cross-system collisions on host-pinned keys silently let the last system win,
  # mirroring how outputs/systems.nix merges nixosConfigurations.
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
in
{
  homeConfigurations = lib.concatMapAttrs (
    system: entries:
    lib.mapAttrs' (key: _: {
      name = if lib.hasInfix "@" key then key else "${key}@${system}";
      value = mkHome system key;
    }) entries
  ) homesTree;
}
