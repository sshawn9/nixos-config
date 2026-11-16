{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.fileSources.local) link;
in
{
  config = lib.mkIf config.features.programs.enable {
    xdg.configFile."opencode/AGENTS.md" = lib.mkIf config.programs.opencode.enable (
      link "ai/AGENTS.md"
    );

    programs.opencode = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.opencode;
    };
  };
}
