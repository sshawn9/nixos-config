{
  myLib,
  pkgs,
  ...
}:
let
  inherit (myLib) mkSystemPackages;
in
{
  imports = [
    (mkSystemPackages {
      llama-cpp = {
        package = pkgs.unstable.llama-cpp.override {
          cudaSupport = true;
        };
      };
    })
  ];
}
