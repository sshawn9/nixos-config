{ lib, config, ... }:

{
  xdg.portal = {
    enable = lib.mkDefault (config.my.shared.desktop.active != [ ]);
    xdgOpenUsePortal = lib.mkDefault (config.my.shared.desktop.active != [ ]);
  };
}
