{ inputs, lib, ... }:
let
  # haumea
  # Scope:   internal
  # Returns: haumea library namespace
  # Use:     shared loader backend for all public module path helpers
  # Notes:   haumea.load provides the directory traversal and "_" visibility
  #          convention used by this file
  # Example:
  #   haumea.load { src = ./features; loader = haumea.loaders.path; }
  #   => { git = ./features/git.nix; shell.zsh = ./features/shell/zsh.nix; }
  haumea = inputs.haumea.lib;

  # flattenAttrTreeToList
  # Scope:   universal
  # Returns: flat list of every non-attr value reachable in a nested attrset
  # Use:     convert a tree-shaped attrset (e.g. haumea's load output) into a
  #          flat list of leaves; useful when callers already hold a loaded
  #          tree and just need an imports-style list
  # Notes:   attr names are discarded; list order follows builtins.attrValues
  #          at each level; non-attrset values (paths, strings, lists,
  #          functions, ...) are treated uniformly as leaves
  # Example:
  #   flattenAttrTreeToList { git = ./git.nix; shell.zsh = ./shell/zsh.nix; }
  #   => [ ./git.nix ./shell/zsh.nix ]
  flattenAttrTreeToList = lib.collect (x: !lib.isAttrs x);

  # selectShallowModule
  # Scope:   internal
  # Returns: module path for a top-level file or a subdirectory's default.nix
  # Use:     implement shallow loaders
  # Notes:   subdirectories without default.nix fail early with a focused error
  # Example:
  #   Directory:
  #     ./features/git.nix
  #     ./features/shell/default.nix
  #     ./features/shell/zsh.nix
  #
  #   Recursive haumea output:
  #     {
  #       git = ./features/git.nix;
  #       shell = {
  #         default = ./features/shell/default.nix;
  #         zsh = ./features/shell/zsh.nix;
  #       };
  #     }
  #
  #   Shallow loading keeps only one module per top-level entry:
  #     git   => ./features/git.nix
  #     shell => ./features/shell/default.nix
  #
  #   So internally:
  #     selectShallowModule ./features "git" ./features/git.nix
  #     => ./features/git.nix
  #
  #     selectShallowModule ./features "shell" { default = ./features/shell/default.nix; zsh = ./features/shell/zsh.nix; }
  #     => ./features/shell/default.nix
  selectShallowModule =
    path: name: value:
    if lib.isAttrs value then
      value.default
        or (throw "myLib.loadShallowModulePathAttrs: ${toString path}/${name} is a directory without default.nix")
    else
      value;

  # loadRecursiveModulePathAttrs
  # Scope:   universal
  # Returns: recursive nested attrset of module paths
  # Use:     flake/module discovery when callers need keyed access
  # Notes:   names starting with "_" are hidden by haumea
  #
  # Example:
  #   ./features/default.nix
  #   ./features/git.nix
  #   ./features/shell/zsh.nix
  #   ./features/_private.nix
  #
  #   loadRecursiveModulePathAttrs ./features
  #   => {
  #        default = ./features/default.nix;
  #        git = ./features/git.nix;
  #        shell.zsh = ./features/shell/zsh.nix;
  #      }
  loadRecursiveModulePathAttrs =
    path:
    haumea.load {
      src = path;
      loader = haumea.loaders.path;
    };

  # loadShallowModulePathAttrs
  # Scope:   universal
  # Returns: top-level attrset of module paths
  # Use:     module discovery when only immediate children should be exposed
  # Notes:   subdirectories collapse to their default.nix; missing default.nix
  #          is an explicit error
  #
  # Example:
  #   ./features/default.nix
  #   ./features/git.nix
  #   ./features/shell/default.nix
  #   ./features/shell/zsh.nix
  #
  #   loadShallowModulePathAttrs ./features
  #   => {
  #        default = ./features/default.nix;
  #        git = ./features/git.nix;
  #        shell = ./features/shell/default.nix;
  #      }
  loadShallowModulePathAttrs =
    path: lib.mapAttrs (selectShallowModule path) (loadRecursiveModulePathAttrs path);

  # loadRecursiveModulePathList
  # Scope:   universal
  # Returns: recursive flat list of module paths
  # Use:     imports lists that should include every visible nested module
  # Notes:   includes default.nix when it is visible
  #
  # Example:
  #   imports = loadRecursiveModulePathList ./features;
  #   => [
  #        ./features/default.nix
  #        ./features/git.nix
  #        ./features/shell/zsh.nix
  #      ]
  loadRecursiveModulePathList = path: flattenAttrTreeToList (loadRecursiveModulePathAttrs path);

  # loadShallowModulePathList
  # Scope:   universal
  # Returns: top-level flat list of module paths
  # Use:     imports lists inside a directory's default.nix
  # Notes:   excludes the top-level "default" key so default.nix can call this
  #          on its own directory without importing itself
  #
  # Example:
  #   # ./features/default.nix
  #   imports = loadShallowModulePathList ./.;
  #   => [
  #        ./features/git.nix
  #        ./features/shell/default.nix
  #      ]
  loadShallowModulePathList =
    path: builtins.attrValues (removeAttrs (loadShallowModulePathAttrs path) [ "default" ]);
in
{
  inherit
    flattenAttrTreeToList
    loadRecursiveModulePathList
    loadRecursiveModulePathAttrs
    loadShallowModulePathList
    loadShallowModulePathAttrs
    ;
}
