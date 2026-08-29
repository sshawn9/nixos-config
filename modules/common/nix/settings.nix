{ lib, inputs, ... }:

{
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nix.settings = {
    auto-optimise-store = true;
    max-jobs = lib.mkDefault 2;
    cores = lib.mkDefault 16;

    extra-substituters = lib.mkBefore [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos-cuda.org"
      "https://claude-code.cachix.org"
      "https://codex-cli.cachix.org"
      "https://noctalia.cachix.org"
      "https://nix-community.cachix.org"
      "https://mousehop.cachix.org"
      "https://pyproject-nix.cachix.org"
    ];

    extra-trusted-public-keys = lib.mkBefore [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
      "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "mousehop.cachix.org-1:5wbRclpnaMFh5hRLx4BR+UMSkOfCiR2kfr6WLItDpPU="
      "pyproject-nix.cachix.org-1:UNzugsOlQIu2iOz0VyZNBQm2JSrL/kwxeCcFGw+jMe0="
    ];

    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
