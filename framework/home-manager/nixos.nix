{
  inputs,
  lib,
  self,
  ...
}:
{
  _class = "nixos";
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = lib.mkDefault true;
    useUserPackages = lib.mkDefault true;
    backupFileExtension = lib.mkDefault "hm-backup";
    extraSpecialArgs = { inherit inputs self; };
    sharedModules = [ self.homeModules.homeManager ];
  };
}
