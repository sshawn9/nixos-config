{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:

{
  home.file.".codex/AGENTS.md".source = config.my.paths.local.dotfilesLayeredSource "ai/AGENTS.md";

  xdg.configFile."opencode/AGENTS.md" = lib.mkIf config.programs.opencode.enable {
    source = config.my.paths.local.dotfilesLayeredSource "ai/AGENTS.md";
  };

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
