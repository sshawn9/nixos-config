{
  myLib,
  config,
  ...
}:
let
  inherit (myLib) mkHomePackages;
in
{
  imports = [
    (mkHomePackages {
      haruna = {
      };
    })
  ];

  xdg.configFile."haruna" = config.my.paths.local.xdgConfigLayeredTree "haruna";
}
