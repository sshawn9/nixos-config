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
  directory = self.outPath + "/compositions/hosts";
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
      configuration = withSystem entry.system (
        { pkgs, ... }:
        inputs.nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs self; };
          modules = [
            self.nixosModules.commonOptions
            self.nixosModules.package
            self.nixosModules.fileSources
            self.nixosModules.allFeatures
            inputs.home-manager.nixosModules.home-manager
            ./shared-options.nix
            {
              nixpkgs.pkgs = pkgs;
              home-manager = {
                useGlobalPkgs = lib.mkDefault true;
                useUserPackages = lib.mkDefault true;
                extraSpecialArgs = { inherit inputs self; };
                sharedModules = [
                  self.homeModules.commonOptions
                  self.homeModules.package
                  self.homeModules.fileSources
                  self.homeModules.allFeatures
                ];
              };
            }
          ]
          ++ moduleFiles.list entry.path;
        }
      );
    in
    [ (lib.nameValuePair "${entry.name}@${entry.system}" configuration) ]
    ++ lib.optional (nameCounts.${entry.name} == 1) (lib.nameValuePair entry.name configuration)
  ) entries;
in
{
  systems = builtins.attrNames platforms;
  flake.nixosConfigurations = lib.listToAttrs configurations;
}
