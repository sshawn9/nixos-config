{
  lib,
  ...
}:
{
  my.packages = {
    sqlite = lib.mkDefault true;
    sqlitebrowser = lib.mkDefault false;
  };
}
