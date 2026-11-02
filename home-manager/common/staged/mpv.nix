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

  programs.mpv = {
    # Keep the compiled player on nix-packages' pins; only rebuild its script wrapper.
    package = pkgs.mpv.override {
      mpv-unwrapped = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.mpv.unwrapped;
      # Home Manager only wraps programs.mpv.scripts with its default package.
      scripts = with pkgs.mpvScripts; [
        mpris
        uosc
        thumbfast
      ];
    };
  };
}
