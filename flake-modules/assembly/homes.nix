{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (config.flake.lib) moduleFiles pkgsFor;
  directory = config.homes.directory;
  tree = if builtins.pathExists directory then moduleFiles.recursive.attrs directory else { };
  # Darwin assembly can be added independently of discovery and output naming.
  homesTree = lib.filterAttrs (system: _: lib.hasSuffix "-linux" system) tree;

  entries = lib.concatLists (
    lib.mapAttrsToList (
      system: homes:
      lib.mapAttrsToList (key: files: {
        inherit system key;
        modules = moduleFiles.flatten files;
      }) homes
    ) homesTree
  );

  keyCounts = lib.foldl' (
    counts: entry: counts // { ${entry.key} = (counts.${entry.key} or 0) + 1; }
  ) { } entries;

  configurations = map (
    entry:
    let
      inherit (entry) system key;
      username = builtins.head (lib.splitString "@" key);
    in
    {
      inherit system;
      names = [ "${key}@${system}" ] ++ lib.optional (keyCounts.${key} == 1) key;
      configuration = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor system;
        extraSpecialArgs = {
          inherit inputs system username;
          inherit (inputs) self;
        };
        modules = [
          config.flake.modules.generic.framework
          config.flake.modules.generic.allFeatures
        ]
        ++ entry.modules
        ++ [ { home.username = lib.mkDefault username; } ];
      };
    }
  ) entries;
in
{
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    ../features/flake-module.nix
    ../framework/default.nix
  ];

  options.homes.directory = lib.mkOption {
    type = lib.types.path;
    default = inputs.self.outPath + "/homes";
    description = "Standalone Home Manager module directories at <system>/<name>.";
  };

  config = {
    systems = builtins.attrNames homesTree;

    flake.flakeModules.homes = ./homes.nix;

    flake.homeConfigurations = lib.listToAttrs (
      lib.concatMap (
        entry: map (name: lib.nameValuePair name entry.configuration) entry.names
      ) configurations
    );

    perSystem =
      { system, ... }:
      {
        checks = lib.listToAttrs (
          lib.concatMap (
            entry:
            map (name: lib.nameValuePair "home-${name}" entry.configuration.activationPackage) entry.names
          ) (lib.filter (entry: entry.system == system) configurations)
        );
      };
  };
}
