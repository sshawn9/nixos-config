{ lib, inputs, ... }:

{
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nix.settings = {
    auto-optimise-store = true;
    max-jobs = lib.mkDefault 2;
    cores = lib.mkDefault 16;

    trusted-users = [
      "@wheel"
    ];

    extra-substituters = lib.mkBefore [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://noctalia.cachix.org"
      "https://nix-community.cachix.org"
    ];

    extra-trusted-public-keys = lib.mkBefore [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
