{
  lib,
  pkgs,
  config,
  ...
}:

{
  xdg.configFile."opencode/AGENTS.md" = lib.mkIf config.programs.opencode.enable {
    source = config.my.paths.local.dotfilesLayeredSource "ai/AGENTS.md";
  };

  programs = {
    opencode = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.opencode;
    };
  };
}
