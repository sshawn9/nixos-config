{ self, ... }:
{
  imports = [
    self.homeModules.fileSources
    self.homeModules.package
    ./home-manager/ghostty.nix
    ./home-manager/nushell.nix
    ./home-manager/packages.nix
    ./home-manager/shell.nix
    ./home-manager/tmux.nix
    ./home-manager/zellij.nix
    ./home-manager/zsh.nix
  ];
}
