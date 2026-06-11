{
  lib,
  pkgs,
  config,
  ...
}:
let
  shellModes = [
    "emacs"
    "vi_normal"
    "vi_insert"
  ];

  ideCompletionEvent = {
    until = [
      {
        send = "menu";
        name = "ide_completion_menu";
      }
      { send = "menunext"; }
      { edit = "complete"; }
    ];
  };
in
{
  programs.nushell = {
    enable = lib.mkDefault true;
    package = pkgs.unstable.nushell;

    environmentVariables = {
      CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
    };

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
          mode = shellModes;
          event = ideCompletionEvent;
        }
      ];
    };

    shellAliases = {
      jg = "just --justfile ${config.xdg.configHome}/just/justfile --working-directory .";
    };
  };
}
