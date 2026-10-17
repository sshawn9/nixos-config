{
  lib,
  ...
}:
{
  my.packages = {
    ghq = lib.mkDefault true;
    gfold = lib.mkDefault true;
    gita = lib.mkDefault true;
  };
}
