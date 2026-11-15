{ inputs, lib, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.flakeModules ];

  options.flake.lib.moduleFiles = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = import ./discovery.nix {
      inherit lib;
      haumea = inputs.haumea.lib;
    };
    description = "Discover module paths as trees or import lists without evaluating the files.";
  };

  config.flake.flakeModules.moduleFiles = ./default.nix;
}
