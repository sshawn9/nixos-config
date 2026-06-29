{
  inputs,
  lib,
  ...
}:

{
  imports = [ inputs.mousehop.homeManagerModules.default ];

  programs.mousehop = {
    enable = lib.mkDefault true;
  };
}
