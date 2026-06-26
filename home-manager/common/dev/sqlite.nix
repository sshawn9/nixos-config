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
      sqlite = {
        enable = true;
      };
      sqlitebrowser = {
        enable = true;
      };
    })
  ];
}
