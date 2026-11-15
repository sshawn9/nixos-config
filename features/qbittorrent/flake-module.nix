{
  flake = {
    nixosModules.qbittorrent = ./nixos.nix;
    homeModules.qbittorrent = ./home-manager.nix;
  };
}
