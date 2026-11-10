{ config, lib, ... }:

let
  inherit (config.my.shared) username;
  loginKeyFile = ../../../.dotfiles/star/.ssh/id_ed25519.pub;
in
{
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "prohibit-password";
  };

  users.users = {
    root = {
      hashedPassword = "!";
      openssh.authorizedKeys.keyFiles = [ loginKeyFile ];
    };

    ${username} = {
      # Keep the password locked regardless of the shared password defaults.
      password = lib.mkForce null;
      hashedPassword = "!";
      hashedPasswordFile = lib.mkForce null;
      openssh.authorizedKeys.keyFiles = [ loginKeyFile ];
    };
  };

  security.sudo.wheelNeedsPassword = false;
}
