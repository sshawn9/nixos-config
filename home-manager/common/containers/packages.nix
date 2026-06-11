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
      regctl = { };
      skopeo = { };
    })
  ];
}
