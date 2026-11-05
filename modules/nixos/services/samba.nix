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

  mkReadOnlyShare = path: {
    inherit path;
    browseable = "yes";
    "read only" = "yes";
    "guest ok" = "no";
    "valid users" = username;
  };
in
{
  services.samba = {
    enable = lib.mkDefault false;
    package = lib.mkDefault pkgs.unstable.samba;
    openFirewall = lib.mkDefault true;

    nmbd.enable = lib.mkDefault false;
    winbindd.enable = lib.mkDefault false;

    settings = {
      Music = mkReadOnlyShare "${user.home}/Music";
      Videos = mkReadOnlyShare "${user.home}/Videos";
    };
  };
}
