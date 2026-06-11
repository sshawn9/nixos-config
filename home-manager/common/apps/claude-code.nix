{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    claude-code = {
      enable = lib.mkDefault false;
      package = inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
  };
}
