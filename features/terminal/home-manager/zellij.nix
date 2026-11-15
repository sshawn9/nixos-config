{ lib, pkgs, ... }:
{
  # Zellij rewrites its configuration from the settings UI; keep that file mutable.
  programs.zellij = {
    enable = lib.mkDefault false;
    package = lib.mkDefault pkgs.unstable.zellij;
  };
}
