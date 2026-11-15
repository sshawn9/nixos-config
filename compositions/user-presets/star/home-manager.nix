{
  config,
  lib,
  pkgs,
  self,
  ...
}:
{
  imports = [
    self.homeModules.homeManager
    self.homeModules.user-environment
    self.homeModules.programs-cli
    self.homeModules.ssh
    self.homeModules.terminal
  ];

  home.username = lib.mkDefault "star";
  home.homeDirectory = lib.mkDefault "/home/${config.home.username}";
  home.stateVersion = lib.mkDefault "25.11";
  home.sessionPath = lib.mkAfter [ "$HOME/.cargo/bin" ];

  fileSources = {
    baseDir = lib.mkDefault ".dotfiles/base";
    overrideDirs = [ ".dotfiles/star" ];
    localRoot = lib.mkDefault "${config.home.homeDirectory}/ghq/github.com/sshawn9/nixos-config";
  };

  programs.git = {
    settings.user = {
      name = lib.mkDefault "sshawn9";
      email = lib.mkDefault "29659937+sshawn9@users.noreply.github.com";
    };
  };
}
