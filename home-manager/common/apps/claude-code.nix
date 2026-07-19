{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    claude-code = {
      package = lib.mkDefault inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
  };
}
