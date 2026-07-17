{
  description = "My Nix/NixOS Configuration";

  outputs = inputs: import ./outputs inputs;

  inputs = {
    # Official NixOS/Nixpkgs repositories, using mirrors for faster access in China.
    # url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-25.11&shallow=1";
    # url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";
    # https://github.com/NixOS/nixpkgs
    # https://wiki.nixos.org/wiki/FAQ#Using_flakes
    nixpkgs-2511 = {
      url = "github:NixOS/nixpkgs/nixos-25.11";
    };
    nixpkgs-2605 = {
      url = "github:NixOS/nixpkgs/nixos-26.05";
    };
    nixpkgs-2605-darwin = {
      url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    };
    nixpkgs-unstable.follows = "nixpkgs-2605-darwin";
    nixpkgs-stable.follows = "nixpkgs-2605-darwin";
    nixpkgs.follows = "nixpkgs-unstable";

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-unstable";
    };

    haumea = {
      url = "github:nix-community/haumea";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    treefmt-preset = {
      url = "github:sshawn9/treefmt-preset";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    t2fanrd = {
      url = "github:GnomedDev/T2FanRD";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell/v4.7.7";
      inputs.nixpkgs.url = "github:NixOS/nixpkgs/da5ad661ba4e5ef59ba743f0d112cbc30e474f32";
      inputs.noctalia-qs = {
        inputs.treefmt-nix.follows = "treefmt-nix";
      };
    };

    bluetooth-auth = {
      url = "github:sshawn9/bluetooth-auth";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-parts.follows = "flake-parts";
    };

    rime-ice = {
      url = "github:iDvel/rime-ice";
      flake = false;
    };

    a2141-brcm-firmware = {
      url = "github:sshawn9/a2141-brcm-firmware";
      flake = false;
    };

    aw-watcher-input-src = {
      url = "github:ActivityWatch/aw-watcher-input";
      flake = false;
    };

    aw-watcher-utilization-src = {
      url = "github:Alwinator/aw-watcher-utilization";
      flake = false;
    };

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database/2026-07-05-062608";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    openfang = {
      url = "github:RightNow-AI/openfang/v0.6.9";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-parts.follows = "flake-parts";
      inputs.rust-flake = {
        inputs.nixpkgs.follows = "nixpkgs-unstable";
        inputs.rust-overlay.follows = "rust-overlay";
      };
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    daeuniverse = {
      url = "github:daeuniverse/flake.nix";
      inputs.flake-parts.follows = "flake-parts";
    };

    mousehop = {
      url = "github:jondkinney/mousehop/v0.14.2";
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
      # inputs.rust-overlay.follows = "rust-overlay";
    };
  };
}
