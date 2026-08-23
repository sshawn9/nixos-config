{ myLib, ... }:
{
  # The shared layer every installation medium gets, the way modules/default.nix
  # is the shared layer every host gets. Each feature under ./installer declares
  # a `my.installer.*` option and stays inert until a medium turns it on.
  #
  # This file sits beside that tree rather than inside it on purpose: a collector
  # that recursed its own directory would import itself and overflow the stack.
  # It cannot be named `installer.nix` either, since a file and a directory of
  # the same name collide in the recursive loader.
  imports = myLib.loadRecursiveModulePathList ./installer;
}
