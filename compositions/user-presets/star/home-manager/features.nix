{ lib, ... }:
{
  features = {
    catppuccin.enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
    nix-ld.enable = lib.mkDefault true;
    programs-cli.enable = lib.mkDefault true;
    ssh.enable = lib.mkDefault true;
    system-base.enable = lib.mkDefault true;
    terminal.enable = lib.mkDefault true;
  };
}
