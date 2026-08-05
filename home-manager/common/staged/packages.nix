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
      antigravity-ide = { };
      code-cursor = { };
      inshellisense = { };
      warp-terminal = { };
    })
  ];
}
