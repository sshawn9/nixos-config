{
  lib,
  ...
}:
{
  my.packages = {
    regctl = lib.mkDefault true;
    skopeo = lib.mkDefault true;
  };
}
