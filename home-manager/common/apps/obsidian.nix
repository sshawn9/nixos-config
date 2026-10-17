{
  lib,
  ...
}:
{
  my.packages.obsidian = lib.mkDefault false;

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

  # Fixed as verified on 2026-10-11 with Obsidian 1.13.7 / Electron 43.7.7:
  # package.json now sets desktopName to "md.obsidian.Obsidian.desktop", and
  # nixpkgs ships that desktop file with StartupWMClass=md.obsidian.Obsidian.
  # The workaround below is no longer needed; enabling it would add a stale
  # obsidian.desktop entry alongside the packaged one. Kept for reference.
  # xdg.desktopEntries =
  #   lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && config.my.packages.obsidian.enable)
  #     {
  #       obsidian = {
  #         name = "Obsidian";
  #         comment = "Knowledge base";
  #         categories = [ "Office" ];
  #         exec = "obsidian %u";
  #         icon = "obsidian";
  #         mimeType = [ "x-scheme-handler/obsidian" ];
  #         type = "Application";
  #         startupNotify = true;
  #         settings = {
  #           StartupWMClass = "electron";
  #           Version = "1.5";
  #         };
  #       };
  #     };
}
