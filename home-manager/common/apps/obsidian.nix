{
  myLib,
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (myLib) mkHomePackages;
in
{
  imports = [
    (mkHomePackages {
      obsidian = {
        enable = true;
      };
    })
  ];

  # Obsidian's Wayland xdg_toplevel app_id is hardcoded to the literal
  # "electron" because its package.json lacks the desktopName field;
  # Electron 41's Ozone/Wayland path ignores argv[0] basename and --class=.
  # See docs/problems/obsidian-gnome-wayland-duplicate-icon.md for details.
  # Override the desktop entry with StartupWMClass=electron so taskbars
  # (GNOME Shell, noctalia, etc.) match that app_id to this entry.
  #
  # xdg.desktopEntries writes a .desktop file, which only has effect on Linux
  # desktops; gating keeps the same module file usable on darwin where these
  # entries would be dead bytes on disk.
  xdg.desktopEntries =
    lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && config.my.packages.obsidian.enable)
      {
        obsidian = {
          name = "Obsidian";
          comment = "Knowledge base";
          categories = [ "Office" ];
          exec = "obsidian %u";
          icon = "obsidian";
          mimeType = [ "x-scheme-handler/obsidian" ];
          type = "Application";
          startupNotify = true;
          settings = {
            StartupWMClass = "electron";
            Version = "1.5";
          };
        };
      };
}
