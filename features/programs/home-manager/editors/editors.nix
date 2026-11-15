{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.fileSources.local.xdgConfig) link;
in
{
  xdg.configFile = lib.mkIf config.programs.vscode.enable {
    "Code/User/settings.json" = link "Code/User/settings.json";
    "Code/User/keybindings.json" = link "Code/User/keybindings.json";
    "Code/User/extensions.json" = link "Code/User/extensions.json";
  };

  programs = {
    vim.enable = lib.mkDefault true;
    helix = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.helix;
    };
    vscode.package = lib.mkDefault pkgs.unstable.vscode;
  };

  package = {
    clion = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.jetbrains.clion;
    };
    pycharm = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.jetbrains.pycharm;
    };
    rust-rover = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.jetbrains.rust-rover;
    };
    antigravity-ide = lib.mkDefault false;
    code-cursor = lib.mkDefault false;
  };
}
