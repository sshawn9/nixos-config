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
  # A host-pinned key shared by multiple systems gains a final @<system> suffix,
  # preventing concatMapAttrs from silently retaining only one architecture.
  defaultName = system: key: if lib.hasInfix "@" key then key else "${key}@${system}";

  nameCounts = lib.foldlAttrs (
    counts: system: entries:
    lib.foldlAttrs (
      counts': key: _:
      let
        name = defaultName system key;
      in
      counts'
      // {
        ${name} = (counts'.${name} or 0) + 1;
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
in
{
  supportedSystems = builtins.attrNames homesTree;

  homeConfigurations = lib.concatMapAttrs (
    system: entries:
    lib.mapAttrs' (
      key: _:
      let
        name = defaultName system key;
        finalName = if nameCounts.${name} == 1 then name else "${name}@${system}";
      in
      lib.nameValuePair finalName (mkHome system key)
    ) entries
  ) homesTree;
}
