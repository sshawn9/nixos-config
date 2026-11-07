{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  xdg.configFile = lib.mkIf config.programs.mpv.enable {
    "mpv/mpv.conf".source = config.my.paths.local.xdgConfigLayeredSource "mpv/mpv.conf";
    "mpv/input.conf".source = config.my.paths.local.xdgConfigLayeredSource "mpv/input.conf";

    # Expose Catppuccin's selected theme without hard-coding its store path in mpv.conf.
    "mpv/catppuccin.conf".source =
      config.programs.mpv.config.include or (pkgs.writeText "mpv-no-theme.conf" "");
  };

  programs.mpv.package = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.mpv;
}
