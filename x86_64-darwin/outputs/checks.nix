{
  lib,
  systems,
  homes,
}:
let
  configurationsForSystem =
    system:
    lib.filterAttrs (_name: configuration: configuration.pkgs.stdenv.hostPlatform.system == system);

  mkConfigurationChecks =
    prefix: getBuild: configurations:
    lib.mapAttrs' (
      name: configuration: lib.nameValuePair "${prefix}-${name}" (getBuild configuration)
    ) configurations;
in
{
  supportedSystems = lib.unique (systems.supportedSystems ++ homes.supportedSystems);

  forSystem =
    system:
    mkConfigurationChecks "nixos" (configuration: configuration.config.system.build.toplevel) (
      configurationsForSystem system systems.nixosConfigurations
    )
    // mkConfigurationChecks "darwin" (configuration: configuration.system) (
      configurationsForSystem system systems.darwinConfigurations
    )
    // mkConfigurationChecks "home" (configuration: configuration.activationPackage) (
      configurationsForSystem system homes.homeConfigurations
    );
}
