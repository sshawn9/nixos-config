{ lib, pkgs, ... }:
{
  my.packages.llama-cpp = {
    enable = lib.mkDefault false;
    package = lib.mkDefault (
      pkgs.unstable.llama-cpp.override {
        cudaSupport = true;
      }
    );
  };
}
