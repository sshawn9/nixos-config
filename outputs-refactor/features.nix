{
  lib,
  options,
  self,
  ...
}:
let
  flakeOptions = options.flake.valueMeta.configuration.options;

  collect =
    namespace:
    let
      names = lib.unique (
        lib.concatMap (
          definition:
          lib.optionals (lib.hasPrefix "${self.outPath}/features/" definition.file) (
            builtins.attrNames definition.value
          )
        ) flakeOptions.${namespace}.definitionsWithLocations
      );
    in
    map (name: self.${namespace}.${name}) names;
in
{
  flake.nixosModules.allFeatures = {
    imports = collect "nixosModules";
  };

  flake.homeModules.allFeatures = {
    imports = collect "homeModules";
  };

  flake.systemManagerModules.allFeatures = {
    imports = collect "systemManagerModules";
  };
}
