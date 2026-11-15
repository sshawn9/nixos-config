{
  config,
  inputs,
  lib,
  ...
}:
let
  moduleFiles = import ./module-files/discovery.nix {
    inherit lib;
    haumea = inputs.haumea.lib;
  };
  framework = config.flake.modules.generic.framework;
in
{
  imports = [ inputs.flake-parts.flakeModules.modules ] ++ moduleFiles.shallow.list ./.;

  flake.modules.generic.framework =
    { options, ... }:
    {
      key = "${toString ./default.nix}#framework";
      config = lib.optionalAttrs (options ? home-manager.sharedModules) {
        home-manager.sharedModules = [ framework ];
      };
    };
}
