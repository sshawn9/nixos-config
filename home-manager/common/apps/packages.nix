{
  lib,
  ...
}:
{
  my.packages = {
    telegram-desktop = lib.mkDefault false;
    google-chrome = lib.mkDefault false;

    ffmpeg-full = lib.mkDefault false;

    losslesscut = lib.mkDefault false;
  };
}
