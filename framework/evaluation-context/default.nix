{ inputs, lib, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.flakeModules ];

  options.flake.lib.evaluationContext = lib.mkOption {
    type = lib.types.functionTo (lib.types.attrsOf lib.types.bool);
    default = import ./context.nix;
    description = "Classify a module evaluation using only its class and Home Manager's parent class.";
  };

  config.flake.flakeModules.evaluationContext = ./default.nix;
}
