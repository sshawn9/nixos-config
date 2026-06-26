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
      # lm_sensors reads Linux kernel hwmon devices; no darwin package exists.
      lm_sensors = {
        enable = true;
      };
    })
  ];
}
