{
  lib,
  pkgs,
  config,
  myLib,
  ...
}:
let
  inherit (myLib) mkHomePackages;

  carapaceConfig = ''
    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  '';

  completionStyles = ''
    zstyle ':completion:*:descriptions' format '[%d]'
    zstyle ':completion:*' menu select
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
    zstyle ':completion:*:git:*' group-order 'main commands' 'alias commands' 'external commands'
  '';

  fzfTabStyles = ''
    # zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
    zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ''${(P)word}'
  '';

  justGlobalCompletions = ''
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

  rosCompletions = ''
    # ROS completions (container only)
    if [[ -n "$DISTROBOX_ENTER_PATH" || -n "$CONTAINER_ID" ]]; then
      # Source the last match (reverse-alphabetical ≈ newest distro)
      _ros_setups=(/opt/ros/*/setup.zsh(NOn))
      (( ''${#_ros_setups} )) && source "''${_ros_setups[-1]}"
      unset _ros_setups

      # ROS: rosbash completions
      [[ "$ROS_VERSION" == "1" ]] && {
        (( $+commands[rosrun] )) && source "$(rospack find rosbash 2>/dev/null)/rosbash" 2>/dev/null
      }

      # ROS 2: argcomplete for ros2/colcon
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

  distroboxEnv = ''
    # Distrobox/container: inject host NixOS + home-manager paths so that
    # nix-managed tools are available inside the container.
    # The /nix mount is bind-mounted by distrobox; ZDOTDIR is inherited
    # from the host, so this .zshenv is sourced automatically.
    if [ -n "$DISTROBOX_ENTER_PATH" ] || [ -n "$CONTAINER_ID" ]; then

      # Detect home-manager profile layout:
      #   - NixOS module mode: /nix/var/nix/profiles/system/etc/profiles/per-user/$USER
      #     (active on this machine -- nixos-a2141 / x)
      #   - Standalone HM:     /nix/var/nix/profiles/per-user/$USER/profile
      #     (fallback; not present on this machine named "x")
      _hm_module_bin="/nix/var/nix/profiles/system/etc/profiles/per-user/$USER/bin"
      _hm_standalone_bin="/nix/var/nix/profiles/per-user/$USER/profile/bin"

      if [ -d "$_hm_module_bin" ]; then
        _hm_bin="$_hm_module_bin"
        _hm_share="/nix/var/nix/profiles/system/etc/profiles/per-user/$USER/share"
      elif [ -d "$_hm_standalone_bin" ]; then
        _hm_bin="$_hm_standalone_bin"
        _hm_share="/nix/var/nix/profiles/per-user/$USER/profile/share"
      else
        _hm_bin=""
        _hm_share=""
      fi

      _sys_bin="/nix/var/nix/profiles/system/sw/bin"
      _sys_share="/nix/var/nix/profiles/system/sw/share"

      # Re-exec into nix's zsh for interactive shells to avoid glibc mismatch.
      # Container zsh (e.g. Ubuntu glibc 2.35) cannot dlopen() nix-built zsh
      # modules like fzf-tab's fzftab.so (requires glibc >= 2.38).
      # Standalone binaries are unaffected (they carry their own interpreter
      # via patchelf), but zsh modules are loaded into the zsh process itself.
      # This also resolves compinit "insecure directories" warnings since
      # nix's zsh uses its own fpath without container system directories.
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

      # Prepend order matters: last prepended = highest priority.
      # Target: _hm_bin > _sys_bin > container_PATH
      # (matches NixOS host behavior where user packages override system)
      case ":$PATH:" in
        *":$_sys_bin:"*) ;;
        *) [ -d "$_sys_bin" ] && export PATH="$_sys_bin:$PATH" ;;
      esac

      if [ -n "$_hm_bin" ]; then
        case ":$PATH:" in
          *":$_hm_bin:"*) ;;
          *) export PATH="$_hm_bin:$PATH" ;;
        esac
      fi

      # Same priority for XDG_DATA_DIRS: HM share > system share
      for _d in "$_sys_share" "$_hm_share"; do
        if [ -n "$_d" ]; then
          case ":$XDG_DATA_DIRS:" in
            *":$_d:"*) ;;
            *) [ -d "$_d" ] && export XDG_DATA_DIRS="$_d:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" ;;
          esac
        fi
      done

      unset _hm_module_bin _hm_standalone_bin _hm_bin _hm_share _sys_bin _sys_share _d

      # Use container's sudo — NixOS sudo lacks setuid bit inside containers
      [ -x /usr/bin/sudo ] && alias sudo='/usr/bin/sudo'
    fi
  '';
in
{
  imports = [
    (mkHomePackages {
      zsh-completions = {
        enable = true;
      };
    })
  ];

  programs = {
    zsh = {
      enable = lib.mkDefault true;
      package = pkgs.unstable.zsh;
      dotDir = "${config.xdg.configHome}/zsh";

      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      autocd = true;

      plugins = [
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
          file = "share/fzf-tab/fzf-tab.plugin.zsh";
        }
      ];

      envExtra = distroboxEnv;

      initContent =
        let
          early = lib.mkOrder 500 ''
            # early
          '';

          before = lib.mkOrder 550 ''
            # before
          '';

          general = lib.mkOrder 1000 (
            ''
              # general
            ''
            + carapaceConfig
            + completionStyles
            + fzfTabStyles
            + rosCompletions
          );

          last = lib.mkOrder 1500 (
            ''
              # last
            ''
            + lib.optionalString config.programs.uv.enable ''
              compdef _uv uv
              compdef _uvx uvx
            ''
            + justGlobalCompletions
          );
        in
        lib.mkMerge [
          early
          before
          general
          last
        ];
    };
  };
}
