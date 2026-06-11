{ inputs, config, ... }:

{
  imports = [ inputs.catppuccin.nixosModules.catppuccin ];

  catppuccin = {
    enable = true;
    autoEnable = true;
    inherit (config.my.shared.catppuccin) flavor accent;

    cache.enable = true;

    cursors.enable = true;

    fcitx5 = {
      enable = true;
      enableRounded = true;
    };

    tty.enable = true;
  };
}
