{
  lib,
  pkgs,
  ...
}:

{
  programs = {
    tmux = {
      enable = lib.mkDefault true;
      package = pkgs.unstable.tmux;
      mouse = lib.mkDefault true;
      historyLimit = lib.mkDefault 100000;
      escapeTime = lib.mkDefault 0;
      terminal = lib.mkDefault "tmux-256color";

      plugins = with pkgs.unstable.tmuxPlugins; [
        sensible # Community baseline: utf-8, focus-events, aggressive-resize, etc.
        vim-tmux-navigator # Ctrl+h/j/k/l to seamlessly navigate between vim splits and tmux panes
        catppuccin # Color theme
        {
          plugin = resurrect; # Save and restore windows, panes, and their layout after tmux server restart
          extraConfig = ''
            set -g @resurrect-strategy-nvim 'session' # Also restore neovim sessions (requires Session.vim)
            set -g @resurrect-capture-pane-contents 'on' # Include pane visible text in saved state
          '';
        }
        {
          plugin = continuum; # Automatically trigger resurrect save on interval
          extraConfig = ''
            set -g @continuum-restore 'on' # Auto-restore last saved session on tmux start
            set -g @continuum-save-interval '5' # Save every 5 minutes, default 15
          '';
        }
      ];

      extraConfig = ''
        # Enable true color support
        set -ga terminal-overrides ",*256col*:Tc"

        # New panes inherit the current working directory
        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
      '';
    };
  };
}
