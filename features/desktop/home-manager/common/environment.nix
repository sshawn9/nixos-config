{ config, lib, ... }:
{
  config = lib.mkIf config.features.desktop.enable {
    home.sessionVariables.NIXOS_OZONE_WL = lib.mkDefault "1";
    dconf = {
      enable = lib.mkDefault true;
      settings."org/gnome/desktop/interface".toolkit-accessibility = lib.mkDefault true;
    };
  };
}
