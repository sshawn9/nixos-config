{ config, lib, ... }:
{
  _class = "systemManager";
  imports = [ ./options.nix ];

  environment.systemPackages = lib.concatMap (entry: lib.optional entry.enable entry.package) (
    builtins.attrValues config.package
  );
}
