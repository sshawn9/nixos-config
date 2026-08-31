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
      psmisc = {
        enable = true;
      };
      traceroute = {
        enable = true;
      };
      mtr = {
        enable = true;
      };
      ethtool = {
        enable = true;
      };
      patchelf = {
        enable = true;
      };
      elfutils = {
        enable = true;
      };
      tcpdump = {
        enable = true;
      };
      iotop = {
        enable = true;
      };
    })
  ];
}
