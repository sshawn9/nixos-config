{
  lib,
  pkgs,
  ...
}:

{
  programs = {
    zellij = {
      enable = lib.mkDefault true;
      package = pkgs.unstable.zellij;

      settings = {
        theme = "catppuccin-mocha";
        default_layout = "compact"; # Bottom status bar only, default has both top and bottom
        pane_frames = false; # Hide pane borders for cleaner look, default true

        mouse_mode = true; # Click to focus panes, drag to resize, scroll history
        copy_command = "wl-copy"; # Pipe selections to Wayland clipboard
        copy_clipboard = "primary"; # Copy to primary selection (middle-click paste), default "system"
        session_serialization = true; # Persist session state across exit/restart, default true
      };
    };
  };
}
