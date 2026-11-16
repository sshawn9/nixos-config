{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.programs.enable {
    programs.discord = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.discord;
    };
  };
}
