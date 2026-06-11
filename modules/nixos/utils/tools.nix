{
  lib,
  ...
}:

{
  programs = {
    sniffnet = {
      enable = lib.mkDefault false;
    };
  };
}
