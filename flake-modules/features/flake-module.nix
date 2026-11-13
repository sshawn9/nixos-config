{
  config,
  inputs,
  lib,
  ...
}:
let
  discoverFeatures = import ./discover-features.nix {
    inherit lib;
    haumea = inputs.haumea.lib;
  };
  featureEntries = discoverFeatures ./.;
  mkFeatureModule = import ./mk-feature-module.nix {
    inherit lib;
    inherit (config.flake.lib) evaluationContext;
  };
  guardFeatureConfig = import ./guard-feature-config.nix { inherit lib; };
  scopeFeatureOptions = import ./scope-feature-options.nix { inherit lib; };
  buildFeatureTree =
    f:
    lib.foldl' lib.recursiveUpdate { } (
      map (entry: lib.setAttrByPath entry.path (f entry)) featureEntries
    );

  mkFeaturePartType =
    wrap:
    lib.types.nullOr (
      lib.mkOptionType {
        name = "featureModule";
        description = "feature module";
        check = lib.types.deferredModule.check;
        merge =
          loc: defs:
          lib.types.deferredModule.merge loc (
            map (
              def:
              let
                isFile = lib.types.path.check def.value;
              in
              def
              // {
                value = wrap (lib.init loc) {
                  module = lib.toFunction (if isFile then import def.value else def.value);
                  location = lib.optionalAttrs isFile {
                    _file = toString def.value;
                    key = toString def.value;
                  };
                };
              }
            ) defs
          );
      }
    );

  featureDefinitionType = lib.types.submodule {
    options = {
      enable = lib.mkEnableOption "the feature by default in NixOS and Home Manager";
      options = lib.mkOption {
        type = mkFeaturePartType scopeFeatureOptions;
        default = null;
        description = "Shared option declarations relative to the feature, evaluated in the target context.";
      };
    }
    // lib.genAttrs [ "nixos" "homeManager" ] (
      class:
      lib.mkOption {
        type = mkFeaturePartType guardFeatureConfig;
        default = null;
        description = "The ${class} part of the feature.";
      }
    );
  };
in
{
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    ../framework/evaluation-context/default.nix
  ];

  options.features = lib.mkOption {
    type = lib.types.submodule {
      options = buildFeatureTree (
        entry:
        lib.mkOption {
          type = featureDefinitionType;
          default = { };
          description = "Definition of the ${lib.concatStringsSep "/" entry.path} feature.";
        }
      );
    };
    default = { };
    description = "Feature definitions arranged by their directory paths.";
  };

  options.flake.featureModules = lib.mkOption {
    type = lib.types.raw;
    description = "Computed tree of feature modules, arranged by feature path.";
  };

  config = {
    features = buildFeatureTree (
      entry: { ... }: {
        imports = entry.modules;
      }
    );
    flake = {
      flakeModules.features = ./flake-module.nix;
      featureModules = buildFeatureTree (
        entry: mkFeatureModule entry.path (lib.getAttrFromPath entry.path config.features)
      );
      modules.generic.allFeatures.imports = map (
        entry: lib.getAttrFromPath entry.path config.flake.featureModules
      ) featureEntries;
    };
  };
}
