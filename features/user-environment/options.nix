{ lib, ... }:
{
  options.features.user-environment.enable = lib.mkEnableOption "user XDG directories and session environment";
}
