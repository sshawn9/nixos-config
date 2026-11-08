{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:

{
  home.file.".codex/AGENTS.md" = lib.mkIf config.programs.codex.enable {
    source = config.my.paths.local.dotfilesLayeredSource "ai/AGENTS.md";
  };

  xdg.configFile."opencode/AGENTS.md" = lib.mkIf config.programs.opencode.enable {
    source = config.my.paths.local.dotfilesLayeredSource "ai/AGENTS.md";
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

  programs = {
    codex = {
      # Preserve the complete upstream package layout required by the app-server daemon.
      package = lib.mkDefault (
        inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.codex-node.override {
          nodeBinName = "codex";
        }
      );
    };
    claude-code = {
      package = lib.mkDefault inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
    opencode = {
      package = lib.mkDefault pkgs.unstable.opencode;
    };
    discord = {
      package = lib.mkDefault pkgs.unstable.discord;
    };
  };
}
