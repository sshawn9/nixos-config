{ config, inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.flakeModules ];

  flake = {
    flakeModules.package = ./default.nix;
    modules.generic.package = ./module.nix;
    modules.generic.framework.imports = [ config.flake.modules.generic.package ];
  };
}
