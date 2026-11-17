{ lib, ... }:
{
  options.features.sops = {
    enable = lib.mkEnableOption "SOPS-managed secrets";

    defaultSopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Default encrypted SOPS file shared by NixOS and Home Manager. Individual secrets can specify their own file.";
    };
  };
}
