{ lib, ... }:

{
  nix = {
    daemonCPUSchedPolicy = lib.mkDefault "batch";
    daemonIOSchedClass = lib.mkDefault "idle";
    # daemonIOSchedPriority = lib.mkDefault 7;
  };

  nix.settings.trusted-users = [
    "@wheel"
  ];
}
