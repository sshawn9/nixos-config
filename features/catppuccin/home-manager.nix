{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.features.catppuccin;
in
{
  imports = [
    ./options.nix
    {
      key = "${inputs.catppuccin.outPath}#homeModules.catppuccin";
      imports = [ inputs.catppuccin.homeModules.catppuccin ];
    }
  ];

  config = lib.mkIf config.features.catppuccin.enable {
    catppuccin = {
      enable = lib.mkDefault true;
      autoEnable = lib.mkDefault false;
      flavor = lib.mkDefault cfg.flavor;
      accent = lib.mkDefault cfg.accent;
      cache.enable = lib.mkDefault config.catppuccin.enable;
    };
  };
}
