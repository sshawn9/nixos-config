{ lib, pkgs, ... }:

let
  listenAddress = "127.0.0.1";
in
{
  services.prometheus = {
    enable = lib.mkDefault false;
    package = lib.mkDefault pkgs.unstable.prometheus;

    listenAddress = lib.mkDefault listenAddress;
    port = lib.mkDefault 9092;

    enableReload = lib.mkDefault true;
    checkConfig = lib.mkDefault true;
    retentionTime = lib.mkDefault "30d";
    configText = builtins.readFile ./prometheus.yml;

    exporters = {
      node = {
        enable = lib.mkDefault true;
        listenAddress = lib.mkDefault listenAddress;
        port = lib.mkDefault 9100;
        openFirewall = lib.mkDefault false;

        enabledCollectors = [
          "logind"
          "systemd"
        ];
      };

      blackbox = {
        enable = lib.mkDefault true;
        listenAddress = lib.mkDefault listenAddress;
        port = lib.mkDefault 9115;
        openFirewall = lib.mkDefault false;
        configFile = ./blackbox.yml;
      };

      smartctl = {
        enable = lib.mkDefault true;
        listenAddress = lib.mkDefault listenAddress;
        port = lib.mkDefault 9633;
        openFirewall = lib.mkDefault false;
      };

      process = {
        enable = lib.mkDefault true;
        listenAddress = lib.mkDefault listenAddress;
        port = lib.mkDefault 9256;
        openFirewall = lib.mkDefault false;

        settings.process_names = [
          {
            name = "{{.Comm}}";
            comm = [ ".+" ];
          }
        ];
      };

      snmp = {
        enable = lib.mkDefault true;
        listenAddress = lib.mkDefault listenAddress;
        port = lib.mkDefault 9116;
        openFirewall = lib.mkDefault false;
        configurationPath = ./snmp.yml;
      };
    };
  };
}
