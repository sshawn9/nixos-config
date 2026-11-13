{ lib }:
let
  userSetType = lib.types.attrsOf lib.types.bool;
  defaultUsersModule = {
    # Imported by every feature; declare the shared option only once per host.
    key = "${toString ./flake-module.nix}#defaultUsers";
    options.features.users = lib.mkOption {
      type = userSetType;
      default = { };
      description = "Default embedded Home Manager users for features; false excludes a user.";
    };
  };
in
{
  featureName,
  optionPrefix,
  sharedModule,
  featureModule,
  module,
}:
args@{ config, lib, ... }:
let
  userOptionPath = optionPrefix ++ [ "users" ];
  # Inspect declarations without changing the target option tree or its priorities.
  sharedOptions =
    (lib.types.submoduleWith {
      modules = [ sharedModule ];
      specialArgs = args;
    }).getSubOptions
      [ ];
  defaults = lib.mapAttrsRecursiveCond (value: !lib.isOption value) (
    path: _: lib.mkDefault (lib.getAttrFromPath path config)
  ) (removeAttrs sharedOptions [ "_module" ]);
in
{
  _class = "nixos";
  imports = [ defaultUsersModule ] ++ lib.optional (module != null) module;

  options = lib.setAttrByPath userOptionPath (
    lib.mkOption {
      type = userSetType;
      default = { };
      description = "Embedded Home Manager users for ${featureName}; inherits the host's defaults per user.";
    }
  );
  config =
    lib.setAttrByPath userOptionPath (lib.mapAttrs (_: lib.mkDefault) config.features.users)
    // {
      home-manager.users =
        lib.genAttrs
          (lib.attrNames (lib.filterAttrs (_: enabled: enabled) (lib.getAttrFromPath userOptionPath config)))
          (_: {
            imports = [
              featureModule
              # Selected users follow shared host values unless they override them.
              defaults
            ];
          });
    };
}
