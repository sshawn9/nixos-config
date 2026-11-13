{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (config.flake.lib) moduleFiles pkgsFor;
  directory = config.hosts.directory;
  tree = if builtins.pathExists directory then moduleFiles.recursive.attrs directory else { };
  # Darwin assembly can be added independently of discovery and output naming.
  systemsTree = lib.filterAttrs (system: _: lib.hasSuffix "-linux" system) tree;

  entries = lib.concatLists (
    lib.mapAttrsToList (
      system: hosts:
      lib.mapAttrsToList (hostname: files: {
        inherit system hostname;
        modules = moduleFiles.flatten files;
      }) hosts
    ) systemsTree
  );

  hostnameCounts = lib.foldl' (
    counts: entry: counts // { ${entry.hostname} = (counts.${entry.hostname} or 0) + 1; }
  ) { } entries;

  configurations = map (
    entry:
    let
      inherit (entry) system hostname;
    in
    {
      inherit system;
      names = [ "${hostname}@${system}" ] ++ lib.optional (hostnameCounts.${hostname} == 1) hostname;
      configuration = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs system hostname;
          inherit (inputs) self;
        };
        modules = [
          config.flake.modules.generic.framework
          config.flake.modules.generic.allFeatures
        ]
        ++ entry.modules
        ++ [
          {
            nixpkgs.pkgs = pkgsFor system;
            networking.hostName = lib.mkDefault hostname;
          }
        ];
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

  options.hosts.directory = lib.mkOption {
    type = lib.types.path;
    default = inputs.self.outPath + "/systems";
    description = "NixOS host module directories at <system>/<hostname>.";
  };

  config = {
    systems = builtins.attrNames systemsTree;

    flake.flakeModules.systems = ./systems.nix;

    flake.nixosConfigurations = lib.listToAttrs (
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
            map (
              name: lib.nameValuePair "nixos-${name}" entry.configuration.config.system.build.toplevel
            ) entry.names
          ) (lib.filter (entry: entry.system == system) configurations)
        );
      };
  };
}
