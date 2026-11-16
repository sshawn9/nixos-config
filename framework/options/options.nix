{ lib, ... }:
{
  options.common.primaryUser = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Primary user used by features that need a default user.";
  };
}
