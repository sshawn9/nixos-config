{
  myLib,
  ...
}:
let
  inherit (myLib) mkHomePackages;
in
{
  imports = [
    (mkHomePackages {
      perf = {
        enable = true;
      };
      # nixpkgs marks microsoft-edge unavailable on darwin (only Linux build).
      microsoft-edge = { };
      # lm_sensors reads Linux kernel hwmon devices; no darwin package exists.
      lm_sensors = { };

      cosmic-files = { };
      nemo = { };
    })
  ];
}
