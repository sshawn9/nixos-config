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
    home.file = {
      "${config.programs.claude-code.configDir}/CLAUDE.md" = lib.mkIf config.programs.claude-code.enable (
        link "ai/AGENTS.md"
      );
      ".codex/AGENTS.md" = lib.mkIf config.programs.codex.enable (link "ai/AGENTS.md");
    };

    xdg.configFile."opencode/AGENTS.md" = lib.mkIf config.programs.opencode.enable (
      link "ai/AGENTS.md"
    );

    programs = {
      claude-code = {
        enable = lib.mkDefault false;
        package = lib.mkDefault inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
      codex = {
        enable = lib.mkDefault false;
        package = lib.mkDefault (
          inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.codex-node.override {
            nodeBinName = "codex";
          }
        );
      };
      opencode = {
        enable = lib.mkDefault false;
        package = lib.mkDefault pkgs.unstable.opencode;
      };
    };

    nix.settings = lib.mkMerge [
      (lib.mkIf config.programs.claude-code.enable {
        extra-substituters = [ "https://claude-code.cachix.org" ];
        extra-trusted-public-keys = [
          "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
        ];
      })
      (lib.mkIf config.programs.codex.enable {
        extra-substituters = [ "https://codex-cli.cachix.org" ];
        extra-trusted-public-keys = [
          "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
        ];
      })
    ];
  };
}
