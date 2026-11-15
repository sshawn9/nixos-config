{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.steam = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.unstable.steam;
    dedicatedServer.openFirewall = lib.mkDefault false;
    localNetworkGameTransfers.openFirewall = lib.mkDefault false;
    remotePlay.openFirewall = lib.mkDefault false;
    extest.enable = lib.mkDefault true;
    protontricks.enable = lib.mkDefault true;
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
  programs.gamemode.enable = config.programs.steam.enable;
  programs.gamescope = lib.mkIf config.programs.steam.enable {
    # Steam also supplies a mkDefault false; leave ordinary user values stronger.
    enable = lib.mkOverride 900 true;
    capSysNice = true;
  };
  environment.systemPackages = lib.mkIf config.programs.steam.enable [ pkgs.unstable.mangohud ];
}
