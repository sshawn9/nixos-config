{ lib, ... }:

{
  options.my.shared.cursor.size = lib.mkOption {
    type = lib.types.ints.positive;
    default = 32;
    description = "Pointer cursor size shared by the NixOS session, Home Manager, and compositors.";
  };
}
