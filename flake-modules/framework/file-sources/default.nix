{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.flake-parts.flakeModules.flakeModules ];

  flake = {
    flakeModules.fileSources = ./default.nix;

    modules.generic.fileSources = {
      imports = [ ./module.nix ];
      fileSources.storeRoot = lib.mkOptionDefault inputs.self.outPath;
    };
    modules.generic.framework.imports = [ config.flake.modules.generic.fileSources ];
  };
}
