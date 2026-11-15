{ config, lib, ... }:
{
  _class = "nixos";
  imports = [ ./options.nix ];

  # Disabled entries do not force their package, including missing defaults.
  environment.systemPackages = lib.concatMap (entry: lib.optional entry.enable entry.package) (
    builtins.attrValues config.package
  );
}
