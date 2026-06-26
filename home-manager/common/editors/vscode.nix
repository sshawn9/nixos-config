{
  lib,
  pkgs,
  config,
  ...
}:
{
  xdg.configFile."Code/User/settings.json" = lib.mkIf config.programs.vscode.enable {
    source = config.my.paths.local.xdgConfigLayeredSource "Code/User/settings.json";
  };
  xdg.configFile."Code/User/extensions.json" = lib.mkIf config.programs.vscode.enable {
    source = config.my.paths.local.xdgConfigLayeredSource "Code/User/extensions.json";
  };

  programs = {
    vscode = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.vscode;
    };
  };
}
