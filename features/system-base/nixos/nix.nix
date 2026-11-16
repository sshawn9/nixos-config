{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.features.system-base.enable && config.nix.enable) {
    nix = {
      package = lib.mkDefault pkgs.unstable.nix;
      registry.nixpkgs.flake = lib.mkDefault inputs.nixpkgs;

      settings = {
        auto-optimise-store = lib.mkDefault true;
        experimental-features = lib.mkDefault [
          "nix-command"
          "flakes"
        ];
        trusted-users = [ "@wheel" ];
      };

      daemonCPUSchedPolicy = lib.mkDefault "batch";
      daemonIOSchedClass = lib.mkDefault "idle";

      gc = {
        dates = lib.mkDefault "weekly";
        options = lib.mkDefault "--delete-older-than 60d";
      };
    };

    systemd.services.nix-daemon.serviceConfig = {
      CPUAccounting = lib.mkDefault true;
      IOAccounting = lib.mkDefault true;
      MemoryAccounting = lib.mkDefault true;
      TasksAccounting = lib.mkDefault true;
      CPUWeight = lib.mkDefault 25;
      IOWeight = lib.mkDefault 25;
    };
  };
}
