{ config, lib, ... }:

let
  sopsEnabled = config.my.shared.sops.enable;
in
{
  users.mutableUsers = false;

  users.users.${config.my.shared.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];

    hashedPasswordFile = lib.mkIf sopsEnabled config.sops.secrets.user_password_hash.path;

    # Without sops there is no decrypted hash to point at, so fall back to a
    # clear text password. It ends up world-readable in the Nix store, which is
    # only acceptable for the throwaway hosts that turn sops off.
    password = lib.mkIf (!sopsEnabled) "nixos";
  };

  # neededForUsers puts this one in its own manifest, decrypted early enough
  # for user creation to read the hash.
  sops.secrets.user_password_hash = lib.mkIf sopsEnabled {
    neededForUsers = true;
  };
}
