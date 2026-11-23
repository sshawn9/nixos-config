{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (inputs) self;
  inherit (config.flake.lib) moduleFiles;
  directory = self.outPath + "/compositions/installers";
  tree = if builtins.pathExists directory then moduleFiles.tree directory else { };
  platforms = lib.filterAttrs (
    system: value: lib.isAttrs value && lib.hasSuffix "-linux" system
  ) tree;

  configurations = lib.mapAttrs (
    system: installers:
    lib.mapAttrs (
      name: _:
      self.lib.mkNixosSystem {
        inherit system;
        modules = [ (directory + "/${system}/${name}/live.nix") ];
      }
    ) (lib.filterAttrs (_: lib.isAttrs) installers)
  ) platforms;
in
{
  systems = builtins.attrNames platforms;
  flake.installerConfigurations = configurations;

  perSystem =
    { system, ... }:
    let
      systems = configurations.${system} or { };
    in
    {
      packages = lib.mapAttrs (_: value: value.config.system.build.isoImage) systems;
      checks = lib.mapAttrs' (
        name: value: lib.nameValuePair "installer-${name}" value.config.system.build.isoImage
      ) systems;
    };
}
