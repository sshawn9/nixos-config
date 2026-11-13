{ lib, evaluationContext }:
let
  mkNixOSFeatureModule = import ./mk-nixos-feature-module.nix { inherit lib; };
in
featurePath: feature:
let
  featureName = lib.concatStringsSep "/" featurePath;
  optionPrefix = [ "features" ] ++ featurePath;
  sharedModule = {
    imports = lib.optional (feature.options != null) feature.options;
    options = lib.setAttrByPath (optionPrefix ++ [ "enable" ]) (
      lib.mkEnableOption "the ${featureName} feature" // { default = feature.enable; }
    );
  };
  featureModule =
    args@{ lib, ... }:
    let
      context = evaluationContext args;
    in
    {
      # Keep module identity anchored to the public entry file.
      key = "${toString ./flake-module.nix}#features.${featureName}";
      imports = [
        sharedModule
      ]
      ++ lib.optional context.isNixOS (mkNixOSFeatureModule {
        inherit
          featureName
          optionPrefix
          sharedModule
          featureModule
          ;
        module = feature.nixos;
      })
      ++ lib.optional context.isHomeManager {
        _class = "homeManager";
        imports = lib.optional (feature.homeManager != null) feature.homeManager;
      };
    };
in
featureModule
