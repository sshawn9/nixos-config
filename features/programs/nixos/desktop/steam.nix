{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.programs.enable {
    programs.steam = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.steam;
      dedicatedServer.openFirewall = lib.mkDefault false;
      localNetworkGameTransfers.openFirewall = lib.mkDefault false;
      remotePlay.openFirewall = lib.mkDefault false;
      extest.enable = lib.mkDefault true;
      protontricks = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.protontricks;
      };
      gamescopeSession.enable = lib.mkDefault false;
      extraCompatPackages = [ pkgs.unstable.proton-ge-bin ];
      extraPackages = with pkgs.unstable; [
        libpulseaudio
        stdenv.cc.cc.lib
        libkrb5
        keyutils
      ];
    };
    hardware.steam-hardware.enable = config.programs.steam.enable;
    programs.gamemode = {
      enable = config.programs.steam.enable;
      package = lib.mkDefault pkgs.unstable.gamemode;
    };
    programs.gamescope = lib.mkIf config.programs.steam.enable {
      # Steam also supplies a mkDefault false; leave ordinary user values stronger.
      enable = lib.mkOverride 900 true;
      package = lib.mkDefault pkgs.unstable.gamescope;
      capSysNice = true;
    };
    environment.systemPackages = lib.mkIf config.programs.steam.enable [ pkgs.unstable.mangohud ];
  };
}
