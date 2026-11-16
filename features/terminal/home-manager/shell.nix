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

  config = lib.mkIf config.features.terminal.enable {
    xdg.configFile."starship.toml" = lib.mkIf config.programs.starship.enable (link "starship.toml");
    xdg.configFile."atuin/config.toml" = lib.mkIf config.programs.atuin.enable (
      link "atuin/config.toml"
    );

    catppuccin.fzf.enable = lib.mkDefault config.programs.fzf.enable;

    programs = {
      fzf = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.fzf;
        defaultCommand = "${lib.getExe config.programs.fd.package} --type f";
        changeDirWidget.command = "${lib.getExe config.programs.fd.package} --type d";
        historyWidget.command = "";
      };
      atuin = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.atuin;
      };
      starship = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.starship;
      };
      zoxide = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.zoxide;
        options = [ "--cmd cd" ];
      };
    };
  };
}
