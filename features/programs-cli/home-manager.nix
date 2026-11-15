{ self, ... }:
{
  imports = [
    self.homeModules.fileSources
    self.homeModules.package
    ./home-manager/diagnostics.nix
    ./home-manager/diagnostics-linux.nix
    ./home-manager/documentation.nix
    ./home-manager/files.nix
    ./home-manager/network.nix
    ./home-manager/network-linux.nix
    ./home-manager/security.nix
    ./home-manager/text.nix
  ];
}
