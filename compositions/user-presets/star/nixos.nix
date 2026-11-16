{
  lib,
  self,
  ...
}:
{
  imports = [
    self.nixosModules.catppuccin
    self.nixosModules.terminal
  ];

  users.users.star = {
    isNormalUser = lib.mkDefault true;
    extraGroups = [ "wheel" ];
  };

  home-manager.users.star.imports = [ self.homeModules.star ];
}
