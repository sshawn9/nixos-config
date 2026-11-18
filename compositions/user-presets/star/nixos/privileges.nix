{ config, ... }:
let
  inherit (config.common) primaryUser;
in
{
  security.sudo.extraRules = [
    {
      users = [ primaryUser ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user === ${builtins.toJSON primaryUser}) {
        return polkit.Result.YES;
      }
    });
  '';
}
