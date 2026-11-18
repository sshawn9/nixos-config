args@{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  self,
  ...
}:
let
  context = self.lib.evaluationContext args;
  inherit (config.lib.fileSources.local.xdgConfig) link;
in
{
  imports = [
    {
      key = "${inputs.catppuccin.outPath}#homeModules.catppuccin";
      imports = [ inputs.catppuccin.homeModules.catppuccin ];
    }
  ];

  config = lib.mkIf config.features.programs.enable {
    xdg.configFile = lib.mkMerge [
      (lib.mkIf config.programs.mpv.enable {
        "mpv/mpv.conf" = link "mpv/mpv.conf";
        "mpv/input.conf" = link "mpv/input.conf";
        "mpv/catppuccin.conf".source =
          config.programs.mpv.config.include or (pkgs.writeText "mpv-no-theme.conf" "");
      })
      {
        "haruna" = lib.mkIf config.package.haruna.enable (link "haruna");
        "gpu-screen-recorder/config_ui" = lib.mkIf (
          context.isStandaloneHome
          || (
            context.inNixOS
            && osConfig.programs.gpu-screen-recorder.enable
            && osConfig.programs.gpu-screen-recorder.ui.enable
          )
        ) (link "gpu-screen-recorder/config_ui");
      }
    ];

    catppuccin.mpv.enable = lib.mkDefault config.programs.mpv.enable;

    programs.mpv = {
      enable = lib.mkDefault false;
      package = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.mpv;
    };

    package = {
      ffmpeg-full = lib.mkDefault false;
      losslesscut = lib.mkDefault false;
      imagemagick = lib.mkDefault false;
      exiftool = lib.mkDefault false;
      haruna = lib.mkDefault false;
    };
  };
}
