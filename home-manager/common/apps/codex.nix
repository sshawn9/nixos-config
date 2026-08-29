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
      package = lib.mkDefault inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
  };
}
