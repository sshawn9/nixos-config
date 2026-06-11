{ config, lib, ... }:
let
  userName = config.my.shared.username;
  hostName = config.my.shared.hostname;
in
{
  users.users.${userName} = {
    home = "/Users/${userName}";
  };

  networking.hostName = hostName;

  security.pam.services.sudo_local.touchIdAuth = true;

  system = {
    primaryUser = userName;

    activationScripts.postActivation.text = ''
      killall Dock
      killall Finder
    '';

    defaults = {
      dock.show-recents = lib.mkDefault false;

      finder = {
        NewWindowTarget = lib.mkDefault "Home";
      };

      CustomUserPreferences = {
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = lib.mkDefault true;
          DSDontWriteUSBStores = lib.mkDefault true;
        };

        "com.apple.finder" = {
          FXRecentFolders = lib.mkDefault [ ];
        };
      };
    };
  };
}
