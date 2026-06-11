{
  pkgs,
  ...
}:

{
  programs = {
    broot = {
      package = pkgs.unstable.broot;
    };
  };
}
