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

  xdg.configFile."htop/htoprc" = lib.mkIf config.programs.htop.enable (link "htop/htoprc");

  catppuccin.btop.enable = lib.mkDefault config.programs.btop.enable;

  programs = {
    htop = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.htop;
    };
    btop = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.btop;
    };
    fastfetch = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.fastfetch;
    };
  };

  package = {
    lsof = lib.mkDefault true;
    gdu = lib.mkDefault true;
    duf = lib.mkDefault true;
    witr = lib.mkDefault true;
    ncdu = lib.mkDefault true;
    dust = lib.mkDefault true;
    procs = lib.mkDefault true;
  };
}
