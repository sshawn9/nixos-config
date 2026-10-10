{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf (config.my.shared.desktop.active != [ ]) {
    # CUPS also registers cups-pk-helper when polkit is enabled.
    services.printing.enable = lib.mkDefault true;
  };
}
