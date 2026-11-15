{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.nushell = {
    enable = lib.mkDefault false;
    package = lib.mkDefault pkgs.unstable.nushell;
    loadSessionVariables = true;
    settings = {
      show_banner = false;
      history = {
        file_format = "sqlite";
        max_size = 100000;
        sync_on_enter = true;
        isolation = false;
      };
      keybindings = [
        {
          name = "ide_completion_menu_tab";
          modifier = "none";
          keycode = "tab";
          mode = [
            "emacs"
            "vi_normal"
            "vi_insert"
          ];
          event.until = [
            {
              send = "menu";
              name = "ide_completion_menu";
            }
            { send = "menunext"; }
            { edit = "complete"; }
          ];
        }
      ];
    };
    shellAliases.jg = "just --justfile ${config.xdg.configHome}/just/justfile --working-directory .";
  };
}
