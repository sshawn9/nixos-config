{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Zellij rewrites its configuration from the settings UI; keep that file mutable.
  config = lib.mkIf config.features.terminal.enable {
    programs.zellij = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.zellij;
    };
  };
}
