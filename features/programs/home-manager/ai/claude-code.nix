{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.fileSources.local) link;
in
{
  config = lib.mkIf config.features.programs.enable {
    home.file."${config.programs.claude-code.configDir}/CLAUDE.md" =
      lib.mkIf config.programs.claude-code.enable (link "ai/AGENTS.md");

    programs.claude-code = {
      enable = lib.mkDefault false;
      package = lib.mkDefault inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

    nix.settings = lib.mkIf config.programs.claude-code.enable {
      extra-substituters = [ "https://claude-code.cachix.org" ];
      extra-trusted-public-keys = [
        "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
      ];
    };
  };
}
