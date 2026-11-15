{ lib, ... }:
{
  package = {
    ffmpeg-full = lib.mkDefault false;
    losslesscut = lib.mkDefault false;
    qpdf = lib.mkDefault true;
    poppler-utils = lib.mkDefault true;
    imagemagick = lib.mkDefault true;
    exiftool = lib.mkDefault true;
  };
}
