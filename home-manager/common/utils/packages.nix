{ config, lib, ... }:
{
  # Only enabled entries force package evaluation.
  home.packages = lib.concatMap (entry: lib.optional entry.enable entry.package) (
    builtins.attrValues config.my.packages
  );
}
