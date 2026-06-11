{
  inputs,
  pkgs,
  config,
  ...
}:

{
  imports = [ inputs.catppuccin.homeModules.catppuccin ];

  catppuccin = {
    enable = true;
    autoEnable = false;
    inherit (config.my.shared.catppuccin) flavor accent;

    cache.enable = true;

    fzf.enable = true;
    bat.enable = true;
    btop.enable = true;
    zsh-syntax-highlighting.enable = true;

    mpv.enable = true;

    # Cursor and GTK icon themes pull catppuccin-cursors and
    # catppuccin-papirus-folders, which nixpkgs marks unavailable on darwin.
    # Keep them gated to Linux to avoid evaluation failure on macOS.
    cursors.enable = pkgs.stdenv.hostPlatform.isLinux;

    # GTK 4 theme module was archived upstream; only the icon sub-module
    # remains. Provides the Papirus-derived Catppuccin icon set.
    gtk.icon.enable = pkgs.stdenv.hostPlatform.isLinux;
  };
}
