{
  myLib,
  ...
}:
let
  inherit (myLib) mkHomePackages;
in
{
  imports = [
    (mkHomePackages {
      nodejs = {
        enable = true;
      };
    })
  ];
}
