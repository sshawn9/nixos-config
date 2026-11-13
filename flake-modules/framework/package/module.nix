{
  config,
  lib,
  options,
  ...
}:
let
  # Disabled entries do not force their package, including missing defaults.
  selected = lib.concatMap (entry: lib.optional entry.enable entry.package) (
    builtins.attrValues config.package
  );
in
{
  imports = [ ./options.nix ];

  config =
    lib.optionalAttrs (options ? environment.systemPackages) {
      environment.systemPackages = selected;
    }
    // lib.optionalAttrs (options ? home.packages) {
      home.packages = selected;
    }
    // lib.optionalAttrs (options ? home-manager.sharedModules) {
      # Share the API with embedded users; each user selects their own packages.
      home-manager.sharedModules = [ ./module.nix ];
    };
}
