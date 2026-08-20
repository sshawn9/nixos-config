{ lib, ... }:

{
  options.my.shared.sops.enable = lib.mkEnableOption "SOPS-managed secrets" // {
    default = true;
  };
}
