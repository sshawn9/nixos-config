{
  lib,
  pkgs,
  ...
}:

{
  programs = {
    zellij = {
      # TODO: The theme does not follow my.shared.catppuccin. zellij rewrites
      # its own config.kdl from its settings UI, and the current file also
      # depends on a local sidebar layout and plugin, so it stays unmanaged for
      # now. Managing it here would mean moving those settings, layouts and
      # plugins into Nix and giving up saving from the UI.
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.zellij;
    };
  };
}
