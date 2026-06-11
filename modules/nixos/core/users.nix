{ config, ... }:

{
  users.mutableUsers = false;

  users.users.${config.my.shared.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPasswordFile = config.sops.secrets.user_password_hash.path;
  };
}
