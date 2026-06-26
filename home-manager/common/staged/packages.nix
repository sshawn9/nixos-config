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
      antigravity = { };
      code-cursor = { };
      inshellisense = { };
      warp-terminal = { };
    })
  ];
}
