{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.fileSources.local.xdgConfig) link;
in
{
  imports = [
    {
      key = "${inputs.catppuccin.outPath}#homeModules.catppuccin";
      imports = [ inputs.catppuccin.homeModules.catppuccin ];
    }
  ];

  xdg.configFile = lib.mkIf config.programs.mpv.enable {
    "mpv/mpv.conf" = link "mpv/mpv.conf";
    "mpv/input.conf" = link "mpv/input.conf";
    "mpv/catppuccin.conf".source =
      config.programs.mpv.config.include or (pkgs.writeText "mpv-no-theme.conf" "");
  };

  catppuccin.mpv.enable = lib.mkDefault config.programs.mpv.enable;

  programs.mpv = {
    enable = lib.mkDefault false;
    package = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.mpv;
  };
}
