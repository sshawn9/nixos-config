{
  inputs,
  lib,
  config,
  ...
}:

{
  imports = [ inputs.catppuccin.homeModules.catppuccin ];

  catppuccin = {
    enable = lib.mkDefault true;
    autoEnable = false;
    inherit (config.my.shared.catppuccin) flavor accent;

    cache.enable = lib.mkDefault true;
  };
}
