{ lib, hostname, ... }:

{
  options.my.shared.hostname = lib.mkOption {
    type = lib.types.str;
    description = "The hostname of the system.";
  };

  config.my.shared.hostname = lib.mkDefault hostname;
}
