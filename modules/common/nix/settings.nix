{ lib, inputs, ... }:

{
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nix.settings = {
    auto-optimise-store = true;
    max-jobs = lib.mkDefault 2;
    cores = lib.mkDefault 16;

    extra-substituters = lib.mkBefore [
      "https://nix-community.cachix.org"
      "https://sshawn9.cachix.org"
    ];

    extra-trusted-public-keys = lib.mkBefore [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "sshawn9.cachix.org-1:RHYGWuav56oECYgrMMsnyOn3t2sbLQVIr4dEZ4H5J5k="
    ];

    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
