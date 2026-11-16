{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  completionStyles = ''
    _comp_options+=(globdots)
    zstyle ':completion:*:descriptions' format '[%d]'
    zstyle ':completion:*' menu select
    zstyle ':completion:*' force-list always
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
    zstyle ':completion:*:git:*' group-order 'main commands' 'alias commands' 'external commands'
    zstyle ':fzf-tab:complete:cd:*' fzf-preview '${lib.getExe config.programs.eza.package} -a -1 --color=always $realpath'
    zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ''${(P)word}'
  '';

  justCompletions = ''
    jg() {
      command just --justfile "''${XDG_CONFIG_HOME:-$HOME/.config}/just/justfile" --working-directory . "$@"
    }
    _jg() {
      local justfile="''${XDG_CONFIG_HOME:-$HOME/.config}/just/justfile"
      local just_completion="''${_comps[just]-}"
      local -x JUST_JUSTFILE="$justfile"
      local -x JUST_WORKING_DIRECTORY=.
      autoload -Uz _just
      _just "$@"
      local ret=$?
      case "$just_completion" in
        ("") compdef -d just ;;
        (*) compdef "$just_completion" just ;;
      esac
      return $ret
    }
    compdef _jg jg
  '';

  containerEnabled = (config.features.container.enable or false) && pkgs.stdenv.hostPlatform.isLinux;

  rosCompletions = ''
    if [[ -n "$DISTROBOX_ENTER_PATH" || -n "$CONTAINER_ID" ]]; then
      _ros_setups=(/opt/ros/*/setup.zsh(NOn))
      (( ''${#_ros_setups} )) && source "''${_ros_setups[-1]}"
      unset _ros_setups
      [[ "$ROS_VERSION" == "1" ]] && {
        (( $+commands[rosrun] )) && source "$(rospack find rosbash 2>/dev/null)/rosbash" 2>/dev/null
      }
      [[ "$ROS_VERSION" == "2" ]] && {
        autoload -U bashcompinit && bashcompinit
        local _argcomplete=''${commands[register-python-argcomplete3]:-''${commands[register-python-argcomplete]}}
        [[ -n "$_argcomplete" ]] && {
          eval "$("$_argcomplete" ros2)"
          eval "$("$_argcomplete" colcon)"
        }
      }
    fi
  '';

  hostProfileDirectory = ''
    _hm_profile=${lib.escapeShellArg config.home.profileDirectory}
    case "$_hm_profile" in
      /etc/profiles/per-user/*) _hm_profile="/nix/var/nix/profiles/system$_hm_profile" ;;
    esac
    for _hm_profile in \
      "$_hm_profile" \
      "/nix/var/nix/profiles/system/etc/profiles/per-user/$USER" \
      "/nix/var/nix/profiles/per-user/$USER/profile"; do
      [ -d "$_hm_profile/bin" ] && break
      _hm_profile=""
    done
  '';

  containerEnvironment = ''
    if [ -n "$DISTROBOX_ENTER_PATH" ] || [ -n "$CONTAINER_ID" ]; then
      ${hostProfileDirectory}
      _hm_bin="''${_hm_profile:+$_hm_profile/bin}"
      _hm_share="''${_hm_profile:+$_hm_profile/share}"
      _sys_bin="/nix/var/nix/profiles/system/sw/bin"
      _sys_share="/nix/var/nix/profiles/system/sw/share"

      # Container glibc cannot necessarily load Nix-built Zsh plugins.
      if [ -n "$_hm_bin" ] && [ -x "$_hm_bin/zsh" ] && [[ -o interactive ]]; then
        _nix_zsh_real="$(readlink -f "$_hm_bin/zsh")"
        _curr_zsh_real="$(readlink -f /proc/$$/exe)"
        if [ "$_curr_zsh_real" != "$_nix_zsh_real" ]; then
          export SHELL="$_hm_bin/zsh"
          if [[ -o login ]]; then
            exec "$_hm_bin/zsh" --login
          else
            exec "$_hm_bin/zsh" -i
          fi
        fi
        unset _nix_zsh_real _curr_zsh_real
      fi

      # Keep container tools first, followed by the HM and system profiles.
      path=(''${path:#$_hm_bin})
      path=(''${path:#$_sys_bin})
      [ -n "$_hm_bin" ] && path+=("$_hm_bin")
      [ -d "$_sys_bin" ] && path+=("$_sys_bin")
      for _d in "$_sys_share" "$_hm_share"; do
        if [ -n "$_d" ]; then
          case ":$XDG_DATA_DIRS:" in
            *":$_d:"*) ;;
            *) [ -d "$_d" ] && export XDG_DATA_DIRS="$_d:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" ;;
          esac
        fi
      done
      unset _hm_profile _hm_bin _hm_share _sys_bin _sys_share _d
      [ -x /usr/bin/sudo ] && alias sudo='/usr/bin/sudo'
    fi
  '';
in
{
  imports = [
    {
      key = "${inputs.catppuccin.outPath}#homeModules.catppuccin";
      imports = [ inputs.catppuccin.homeModules.catppuccin ];
    }
  ];

  config = lib.mkIf config.features.terminal.enable {
    catppuccin.zsh-syntax-highlighting.enable = lib.mkDefault (
      config.programs.zsh.enable && config.programs.zsh.syntaxHighlighting.enable
    );

    package.zsh-completions = lib.mkIf config.programs.zsh.enable (lib.mkDefault true);

    programs.zsh = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.zsh;
      dotDir = "${config.xdg.configHome}/zsh";
      enableCompletion = true;
      autosuggestion.enable = lib.mkDefault true;
      syntaxHighlighting.enable = lib.mkDefault true;
      autocd = true;
      plugins = [
        {
          name = "fzf-tab";
          src = pkgs.unstable.zsh-fzf-tab;
          file = "share/fzf-tab/fzf-tab.plugin.zsh";
        }
      ];
      envExtra = lib.mkIf containerEnabled containerEnvironment;
      initContent = lib.mkMerge [
        (lib.mkOrder 1000 (completionStyles + lib.optionalString containerEnabled rosCompletions))
        (lib.mkOrder 1500 (
          lib.optionalString config.programs.uv.enable ''
            compdef _uv uv
            compdef _uvx uvx
          ''
          + justCompletions
        ))
      ];
    };
  };
}
