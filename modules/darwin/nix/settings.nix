{ inputs, ... }:

{
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nix.settings.trusted-users = [
    "@admin"
  ];
}
