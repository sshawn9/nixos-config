{
  inputs,
  lib,
  moduleLocation,
  withSystem,
  ...
}:
{
  options.flake.systemManagerModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
    default = { };
    apply = lib.mapAttrs (
      name: module: {
        _class = "systemManager";
        _file = "${moduleLocation}#systemManagerModules.${name}";
        imports = [ module ];
      }
    );
    description = "System Manager modules for non-NixOS Linux hosts.";
  };

  options.flake.lib.mkSystemManager = lib.mkOption {
    type = lib.types.functionTo lib.types.raw;
    default = import ./mk-system-config.nix { inherit inputs withSystem; };
    description = "Assemble a System Manager system with the project's framework and Home Manager.";
  };

  config = {
    perSystem =
      { system, ... }:
      {
        packages = lib.optionalAttrs (lib.hasSuffix "-linux" system) {
          system-manager = inputs.system-manager.packages.${system}.default;
        };
      };
  };
}
