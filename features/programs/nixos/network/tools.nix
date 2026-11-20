{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.features.programs.enable {
    programs = {
      sniffnet.enable = lib.mkDefault false;
    };
  };
}
