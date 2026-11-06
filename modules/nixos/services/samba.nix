# sudo smbpasswd -a <username>

{
  config,
  lib,
  pkgs,
  ...
}:

let
  username = config.my.shared.username;
  user = config.users.users.${username};
in
{
  services.samba = {
    enable = lib.mkDefault false;
    package = lib.mkDefault pkgs.unstable.samba;
    openFirewall = lib.mkDefault true;

    nmbd.enable = lib.mkDefault false;
    winbindd.enable = lib.mkDefault false;

    settings = {
      Public = {
        path = "${user.home}/Public";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = username;
      };
    };
  };
}
