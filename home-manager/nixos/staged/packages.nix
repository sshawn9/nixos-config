{
  lib,
  ...
}:
{
  my.packages = {
    # nixpkgs marks microsoft-edge unavailable on darwin (only Linux build).
    microsoft-edge = lib.mkDefault false;

    cosmic-files = lib.mkDefault false;
    nemo = lib.mkDefault false;
  };
}
