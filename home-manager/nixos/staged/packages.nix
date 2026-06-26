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
      # nixpkgs marks microsoft-edge unavailable on darwin (only Linux build).
      microsoft-edge = { };

      cosmic-files = { };
      nemo = { };
    })
  ];
}
