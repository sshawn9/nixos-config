{
  lib,
  ...
}:
{
  my.packages = {
    antigravity-ide = lib.mkDefault false;
    code-cursor = lib.mkDefault false;
    inshellisense = lib.mkDefault false;
    warp-terminal = lib.mkDefault false;
  };
}
