{ config, inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    inputs.home-manager.flakeModules.home-manager
  ];

  flake = {
    homeModules.package = ./module.nix;
    flakeModules.package = ./default.nix;
    modules.generic.package = ./module.nix;
    modules.generic.framework.imports = [ config.flake.modules.generic.package ];
  };
}
