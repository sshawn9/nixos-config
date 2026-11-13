{
  inputs,
  lib,
  withSystem,
  ...
}:
{
  imports = [ inputs.flake-parts.flakeModules.flakeModules ];

  options.flake.lib.pkgsFor = lib.mkOption {
    type = lib.types.functionTo lib.types.raw;
    default = system: withSystem system ({ pkgs, ... }: pkgs);
    description = "Return the configured perSystem package set for a platform.";
  };

  config.flake.flakeModules.packageSets = ./default.nix;

  config.perSystem =
    { system, ... }:
    {
      _module.args.pkgs = lib.mkDefault (import ./pkgs.nix { inherit inputs; } system);
    };
}
