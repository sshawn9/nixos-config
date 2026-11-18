{ config, lib, ... }:
{
  config = lib.mkIf config.features.programs.enable {
    package = {
      obsidian = lib.mkDefault false;
      qpdf = lib.mkDefault false;
      poppler-utils = lib.mkDefault false;
    };
  };
}
