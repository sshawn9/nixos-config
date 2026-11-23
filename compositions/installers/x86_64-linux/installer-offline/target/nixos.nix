{ config, lib, ... }:
{
  system.stateVersion = lib.mkDefault "26.11";
  i18n.supportedLocales = lib.mkDefault [ "all" ];

  users.mutableUsers = false;
  users.users.${config.common.primaryUser} = {
    isNormalUser = lib.mkDefault true;
    extraGroups = [ "wheel" ];
  };

  # The wizard's autologin choice also applies to this profile's greetd session.
  services.greetd.settings.initial_session =
    lib.mkIf
      (
        config.services.greetd.enable
        && config.programs.niri.enable
        && config.services.displayManager.autoLogin.enable
      )
      {
        command = "${config.programs.niri.package}/bin/niri-session";
        user = config.common.primaryUser;
      };
}
