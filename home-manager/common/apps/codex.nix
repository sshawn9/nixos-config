{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:

{
  home.file.".codex/AGENTS.md" = {
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
  };
}
