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
      stdenv.cc = {
        enable = true;
      };
    })
  ];
}
