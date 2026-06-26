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
      google-chrome = {
        enable = true;
      };
      github-desktop = {
        enable = true;
      };
    })
  ];
}
