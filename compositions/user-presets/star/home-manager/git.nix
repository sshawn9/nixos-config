{ lib, ... }:
{
  programs.git = {
    settings.user = {
      name = lib.mkDefault "sshawn9";
      email = lib.mkDefault "29659937+sshawn9@users.noreply.github.com";
    };
  };
}
