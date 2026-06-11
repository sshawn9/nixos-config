{
  myLib,
  lib,
  system,
  ...
}:
let
  platform = lib.systems.elaborate system;
  inherit (platform) isLinux isDarwin;
in
{
  imports =
    myLib.loadRecursiveModulePathList ./common
    ++ lib.optionals isLinux (myLib.loadRecursiveModulePathList ./nixos)
    ++ lib.optionals isDarwin (myLib.loadRecursiveModulePathList ./darwin);
}
