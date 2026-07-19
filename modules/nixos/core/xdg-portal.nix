{ lib, config, ... }:

{
  xdg.portal = {
    enable = lib.mkDefault (config.my.shared.desktops.active != [ ]);
    xdgOpenUsePortal = lib.mkDefault (config.my.shared.desktops.active != [ ]);
  };
}
