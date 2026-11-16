{
  config,
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf config.features.container.enable {
    systemd.user.tmpfiles.rules = lib.mkIf (!osConfig.virtualisation.waydroid.enable) [
      "r ${builtins.toJSON "${config.xdg.dataHome}/applications/waydroid.*.desktop"} - - - -"
    ];
  };
}
