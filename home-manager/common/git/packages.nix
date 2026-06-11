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
      ghq = {
        enable = true;
      };
      gfold = {
        enable = true;
      };
      gita = {
        enable = true;
      };
    })
  ];
}
