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
    # `nix flake check` already validates `nixosConfigurations` as a standard
    # flake output, so NixOS evaluation failures may be reported once there and
    # once again under `checks`. Keep the explicit check anyway: it makes the
    # system toplevel a buildable check derivation and gives NixOS, nix-darwin,
    # and Home Manager configurations one uniform per-system check interface.
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
