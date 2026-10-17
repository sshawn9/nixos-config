{
  lib,
  ...
}:
{
  my.packages = {
    perf = lib.mkDefault true;
    # lm_sensors reads Linux kernel hwmon devices; no darwin package exists.
    lm_sensors = lib.mkDefault true;
    psmisc = lib.mkDefault true;
    traceroute = lib.mkDefault true;
    mtr = lib.mkDefault true;
    sshfs = lib.mkDefault true;
    ethtool = lib.mkDefault true;
    patchelf = lib.mkDefault true;
    elfutils = lib.mkDefault true;
    tcpdump = lib.mkDefault true;
    iotop = lib.mkDefault true;
    apx = lib.mkDefault true;
    wtype = lib.mkDefault true;
  };
}
