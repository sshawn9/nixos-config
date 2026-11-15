{ config, lib, ... }:
{
  _class = "homeManager";
  imports = [ ./options.nix ];

  # Disabled entries do not force their package, including missing defaults.
  home.packages = lib.concatMap (entry: lib.optional entry.enable entry.package) (
    builtins.attrValues config.package
  );
}
