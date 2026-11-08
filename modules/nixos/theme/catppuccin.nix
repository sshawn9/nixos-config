{
  inputs,
  lib,
  config,
  ...
}:

{
  imports = [ inputs.catppuccin.nixosModules.catppuccin ];

  catppuccin = {
    enable = lib.mkDefault true;
    autoEnable = true;
    inherit (config.my.shared.catppuccin) flavor accent;

    cache.enable = lib.mkDefault true;

    cursors.enable = lib.mkDefault true;

    tty.enable = lib.mkDefault false;
  };
}
