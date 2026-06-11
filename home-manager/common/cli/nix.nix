{
  inputs,
  myLib,
  ...
}:
let
  inherit (myLib) mkHomePackages;
in
{
  imports = [
    inputs.nix-index-database.homeModules.nix-index
    (mkHomePackages {
      nix-output-monitor = {
        enable = true;
      };
      nh = {
        enable = true;
      };
      nvd = {
        enable = true;
      };
      nix-diff = {
        enable = true;
      };
      nix-tree = {
        enable = true;
      };
      statix = {
        enable = true;
      };
      deadnix = {
        enable = true;
      };
      nixfmt = {
        enable = true;
      };
      nix-melt = {
        enable = true;
      };
      nurl = {
        enable = true;
      };
      nix-init = {
        enable = true;
      };
      nixd = {
        enable = true;
      };
    })
  ];

  programs.nix-index-database.comma.enable = true;
}
