{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.programs.enable {
    programs = {
      sniffnet.enable = lib.mkDefault false;

      mosh = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.mosh;
      };
    };
  };
}
