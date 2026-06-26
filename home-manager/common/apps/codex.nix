{
  lib,
  pkgs,
  config,
  ...
}:

{
  home.file.".codex/AGENTS.md" = lib.mkIf config.programs.codex.enable {
    source = config.my.paths.local.dotfilesLayeredSource "ai/AGENTS.md";
  };

  programs = {
    codex = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.codex;
    };
  };
}
