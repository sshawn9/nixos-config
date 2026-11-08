{
  inputs,
  lib,
  pkgs,
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

    # The cursor theme pulls catppuccin-cursors, which nixpkgs marks
    # unavailable on darwin. Keep it gated to Linux to avoid evaluation
    # failure on macOS.
    cursors.enable = pkgs.stdenv.hostPlatform.isLinux;
  };
}
