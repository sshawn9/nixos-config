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
    home.file.".codex/AGENTS.md" = lib.mkIf config.programs.codex.enable (link "ai/AGENTS.md");

    programs.codex = {
      enable = lib.mkDefault false;
      package = lib.mkDefault (
        inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.codex-node.override {
          nodeBinName = "codex";
        }
      );
    };

    nix.settings = lib.mkIf config.programs.codex.enable {
      extra-substituters = [ "https://codex-cli.cachix.org" ];
      extra-trusted-public-keys = [
        "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
      ];
    };
  };
}
