{
  config,
  inputs,
  lib,
  withSystem,
  ...
}:
let
  inherit (inputs) self;
  inherit (config.flake.lib) moduleFiles;
  directory = self.outPath + "/compositions/homes";
  tree = if builtins.pathExists directory then moduleFiles.tree directory else { };
  platforms = lib.filterAttrs (_: lib.isAttrs) tree;

  entries = lib.concatLists (
    lib.mapAttrsToList (
      system: homes:
      lib.mapAttrsToList (name: _: {
        inherit system name;
        path = directory + "/${system}/${name}";
      }) (lib.filterAttrs (_: lib.isAttrs) homes)
    ) platforms
  );

  nameCounts = lib.foldl' (
    counts: entry: counts // { ${entry.name} = (counts.${entry.name} or 0) + 1; }
  ) { } entries;

  configurations = lib.concatMap (
    entry:
    let
      configuration = withSystem entry.system (
        { pkgs, ... }:
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs self; };
          modules = [ self.homeModules.homeManager ] ++ moduleFiles.list entry.path;
        }
      );
    in
    [ (lib.nameValuePair "${entry.name}@${entry.system}" configuration) ]
    ++ lib.optional (nameCounts.${entry.name} == 1) (lib.nameValuePair entry.name configuration)
  ) entries;
in
{
  systems = builtins.attrNames platforms;
  flake.homeConfigurations = lib.listToAttrs configurations;
}
