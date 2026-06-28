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
      github-desktop = {
        enable = true;
      };
    })
  ];
}
