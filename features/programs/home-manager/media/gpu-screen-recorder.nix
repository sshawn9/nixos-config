args@{
  config,
  lib,
  osConfig,
  self,
  ...
}:
let
  context = self.lib.evaluationContext args;
  inherit (config.lib.fileSources.local.xdgConfig) link;
in
{
  config = lib.mkIf config.features.programs.enable {
    xdg.configFile."gpu-screen-recorder/config_ui" = lib.mkIf (
      context.isStandaloneHome
      || (
        context.inNixOS
        && osConfig.programs.gpu-screen-recorder.enable
        && osConfig.programs.gpu-screen-recorder.ui.enable
      )
    ) (link "gpu-screen-recorder/config_ui");
  };
}
