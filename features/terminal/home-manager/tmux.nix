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

  config = lib.mkIf config.features.terminal.enable {
    catppuccin.tmux.enable = lib.mkDefault config.programs.tmux.enable;

    programs.tmux = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.tmux;
      mouse = lib.mkDefault true;
      historyLimit = lib.mkDefault 100000;
      escapeTime = lib.mkDefault 0;
      terminal = lib.mkDefault "tmux-256color";
      plugins = with pkgs.unstable.tmuxPlugins; [
        sensible
        vim-tmux-navigator
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-strategy-nvim 'session'
            set -g @resurrect-capture-pane-contents 'on'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '5'
          '';
        }
      ];
      extraConfig = ''
        set -ga terminal-overrides ",*256col*:Tc"
        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
      '';
    };
  };
}
