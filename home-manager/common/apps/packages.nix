{
  lib,
  config,
  ...
}:
{
  xdg.configFile."haruna" = config.my.paths.local.xdgConfigLayeredTree "haruna";

  my.packages = {
    obsidian = lib.mkDefault false;

    google-chrome = lib.mkDefault false;
    telegram-desktop = lib.mkDefault false;

    haruna = lib.mkDefault false;
    ffmpeg-full = lib.mkDefault false;
    losslesscut = lib.mkDefault false;
  };
}
