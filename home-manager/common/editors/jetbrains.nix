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
      jetbrains = {
        clion = { };
        pycharm = { };
        rust-rover = { };
      };
    })
  ];
}
