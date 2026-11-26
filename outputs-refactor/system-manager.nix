{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (inputs) self;
  inherit (config.flake.lib) moduleFiles;
  directory = self.outPath + "/compositions/system-manager";
  tree = if builtins.pathExists directory then moduleFiles.tree directory else { };
  platforms = lib.filterAttrs (
    system: value: lib.isAttrs value && lib.hasSuffix "-linux" system
  ) tree;

  entries = lib.concatLists (
    lib.mapAttrsToList (
      system: hosts:
      lib.mapAttrsToList (name: _: {
        inherit system name;
        path = directory + "/${system}/${name}";
      }) (lib.filterAttrs (_: lib.isAttrs) hosts)
    ) platforms
  );

  nameCounts = lib.foldl' (
    counts: entry: counts // { ${entry.name} = (counts.${entry.name} or 0) + 1; }
  ) { } entries;

  configurations = lib.concatMap (
    entry:
    let
      configuration = self.lib.mkSystemManager {
        inherit (entry) system;
        modules = moduleFiles.list entry.path;
      };
    in
    [ (lib.nameValuePair "${entry.name}@${entry.system}" configuration) ]
    ++ lib.optional (nameCounts.${entry.name} == 1) (lib.nameValuePair entry.name configuration)
  ) entries;
in
{
  systems = builtins.attrNames platforms;
  flake.systemConfigs = lib.listToAttrs configurations;
}
