{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    claude-code = {
      enable = lib.mkDefault true;
      package = lib.mkDefault inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
  };
}
