{ lib, ... }:

{
  options.my.shared.username = lib.mkOption {
    type = lib.types.str;
    description = "The primary username used across the system.";
  };
}
