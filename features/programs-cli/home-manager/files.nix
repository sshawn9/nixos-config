{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.fileSources.local.xdgConfig) link;
in
{
  imports = [
    {
      key = "${inputs.catppuccin.outPath}#homeModules.catppuccin";
      imports = [ inputs.catppuccin.homeModules.catppuccin ];
    }
  ];

  config = lib.mkIf config.features.programs-cli.enable {
    xdg.configFile."yazi/yazi.toml" = lib.mkIf config.programs.yazi.enable (link "yazi/yazi.toml");

    catppuccin = {
      eza.enable = lib.mkDefault config.programs.eza.enable;
      yazi.enable = lib.mkDefault config.programs.yazi.enable;
    };

    programs = {
      fd = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.fd;
      };
      eza = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.eza;
        git = true;
      };
      yazi = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.yazi;
        shellWrapperName = "y";
      };
      broot.package = lib.mkDefault pkgs.unstable.broot;
    };

    package = {
      file = lib.mkDefault true;
      tree = lib.mkDefault true;
      pv = lib.mkDefault true;
      libarchive = lib.mkDefault true;
      lz4 = lib.mkDefault true;
      brotli = lib.mkDefault true;
      p7zip = lib.mkDefault true;
      unzip = lib.mkDefault true;
      zip = lib.mkDefault true;
    };
  };
}
