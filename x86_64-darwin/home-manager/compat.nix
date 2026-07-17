{
  config,
  lib,
  ...
}:

{
  imports = [
    (lib.mkAliasOptionModule
      [ "programs" "fzf" "changeDirWidget" "command" ]
      [ "programs" "fzf" "changeDirWidgetCommand" ]
    )
  ];

  options.programs.fzf.historyWidget.command = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = ''
      Compatibility option for Home Manager 26.05. fzf 0.72 reads the
      resulting FZF_CTRL_R_COMMAND environment variable directly.
    '';
  };

  config.home.sessionVariables = lib.mkIf (config.programs.fzf.historyWidget.command != null) {
    FZF_CTRL_R_COMMAND = config.programs.fzf.historyWidget.command;
  };
}
