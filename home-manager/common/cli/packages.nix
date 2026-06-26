{
  config,
  lib,
  myLib,
  ...
}:
let
  inherit (myLib) mkHomePackages;
in
{
  imports = [
    (mkHomePackages {
      wget = {
        enable = true;
      };
      curl = {
        enable = true;
      };
      unzip = {
        enable = true;
      };
      just = {
        enable = true;
      };
      witr = {
        enable = true;
      };
      yq = {
        enable = true;
      };
      miller = {
        enable = true;
      };
      jo = {
        enable = true;
      };
      dasel = {
        enable = true;
      };
      sd = {
        enable = true;
      };
      ncdu = {
        enable = true;
      };
      dust = {
        enable = true;
      };
      procs = {
        enable = true;
      };
      xh = {
        enable = true;
      };
      ssh-to-age = {
        enable = true;
      };
      sops = {
        enable = true;
      };
    })
  ];

  xdg.configFile."just" = lib.mkIf config.my.packages.just.enable (
    config.my.paths.local.xdgConfigLayeredTree "just"
  );
}
