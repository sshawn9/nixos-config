{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf (config.my.shared.desktop.active != [ ]) {
    dconf.settings."org/gnome/desktop/interface".toolkit-accessibility = true;
  };
}
