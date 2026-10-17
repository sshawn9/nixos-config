{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.nix-index-database.homeModules.nix-index
  ];

  programs.nix-index-database.comma.enable = lib.mkDefault true;

  my.packages = {
    nix-output-monitor = lib.mkDefault true;
    nh = lib.mkDefault true;
    nvd = lib.mkDefault true;
    nix-diff = lib.mkDefault true;
    nix-tree = lib.mkDefault true;
    statix = lib.mkDefault true;
    deadnix = lib.mkDefault true;
    nixfmt = lib.mkDefault true;
    nix-melt = lib.mkDefault true;
    npc = lib.mkDefault true;
    nurl = lib.mkDefault true;
    nix-init = lib.mkDefault true;
    nixd = lib.mkDefault true;
  };
}
