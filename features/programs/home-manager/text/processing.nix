{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    {
      key = "${inputs.catppuccin.outPath}#homeModules.catppuccin";
      imports = [ inputs.catppuccin.homeModules.catppuccin ];
    }
  ];

  config = lib.mkIf config.features.programs.enable {
    catppuccin.bat.enable = lib.mkDefault config.programs.bat.enable;

    programs = {
      bat = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.bat;
      };
      ripgrep = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.ripgrep;
      };
      ripgrep-all = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.ripgrep-all;
      };
      jq = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.jq;
      };
    };

    package = {
      moreutils = lib.mkDefault true;
      dos2unix = lib.mkDefault true;
      libxml2 = lib.mkDefault true;
      xmlstarlet = lib.mkDefault true;
      yq = lib.mkDefault true;
      miller = lib.mkDefault true;
      jo = lib.mkDefault true;
      dasel = lib.mkDefault true;
      sd = lib.mkDefault true;
      qpdf = lib.mkDefault false;
      poppler-utils = lib.mkDefault false;
    };
  };
}
