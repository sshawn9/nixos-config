{
  pkgs,
  lib,
  config,
  ...
}:

{
  programs.steam = {
    enable = lib.mkDefault false;
    package = lib.mkDefault pkgs.unstable.steam;

    dedicatedServer.openFirewall = lib.mkDefault false;
    localNetworkGameTransfers.openFirewall = lib.mkDefault false;
    remotePlay.openFirewall = lib.mkDefault false;

    extest.enable = lib.mkDefault true;

    protontricks.enable = lib.mkDefault true;

    gamescopeSession.enable = lib.mkDefault false;

    extraCompatPackages = with pkgs.unstable; [
      proton-ge-bin
    ];

    extraPackages = with pkgs.unstable; [
      libpulseaudio
      stdenv.cc.cc.lib
      libkrb5
      keyutils
    ];

    fontPackages = with pkgs.unstable; [
      wqy_zenhei
      noto-fonts-cjk-sans
    ];
  };

  hardware.steam-hardware.enable = config.programs.steam.enable;

  programs.gamemode.enable = config.programs.steam.enable;

  programs.gamescope = lib.mkIf config.programs.steam.enable {
    enable = lib.mkDefault true;
    capSysNice = true;
  };

  environment.systemPackages = lib.mkIf config.programs.steam.enable (
    with pkgs.unstable;
    [
      mangohud
    ]
  );
}
