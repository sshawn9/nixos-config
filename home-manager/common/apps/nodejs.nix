{
  myLib,
  pkgs,
  ...
}:
let
  inherit (myLib) mkHomePackages;
in
{
  imports = [
    (mkHomePackages {
      nodejs = {
        package = pkgs.stable.nodejs_24;
      };
    })
  ];
}
