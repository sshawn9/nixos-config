{
  config,
  lib,
  self,
  ...
}:
let
  inherit (config.common) primaryUser;
  loginKeyFiles = [ (self.outPath + "/file-sources/${primaryUser}/.ssh/id_ed25519.pub") ];
in
{
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "prohibit-password";
  };

  users = {
    mutableUsers = false;
    users = {
      root = {
        hashedPassword = "!";
        openssh.authorizedKeys.keyFiles = loginKeyFiles;
      };

      ${primaryUser} = {
        # The account stays locked even if the preset provides a password.
        password = lib.mkForce null;
        hashedPassword = "!";
        hashedPasswordFile = lib.mkForce null;
        openssh.authorizedKeys.keyFiles = loginKeyFiles;
      };
    };
  };
}
