{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.desktop.enable {
    fonts = {
      enableDefaultPackages = lib.mkDefault true;
      fontDir.enable = lib.mkDefault true;
      packages = import ../../font-packages.nix { inherit pkgs; };
      fontconfig = {
        enable = lib.mkDefault true;
        antialias = lib.mkDefault true;
        hinting = {
          enable = lib.mkDefault true;
          style = lib.mkDefault "slight";
        };
        subpixel = {
          rgba = lib.mkDefault "rgb";
          lcdfilter = lib.mkDefault "default";
        };
        defaultFonts = {
          serif = lib.mkDefault [
            "Noto Serif"
            "Noto Serif CJK SC"
          ];
          sansSerif = lib.mkDefault [
            "Inter"
            "Noto Sans CJK SC"
            "Noto Sans"
          ];
          monospace = lib.mkDefault [
            "JetBrainsMono Nerd Font Mono"
            "Noto Sans Mono CJK SC"
          ];
          emoji = lib.mkDefault [ "Noto Color Emoji" ];
        };
      };
    };
  };
}
