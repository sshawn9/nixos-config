{
  description = "My Nix/NixOS Configuration";

  outputs = inputs: import ./outputs inputs;

  inputs = {
    # Official NixOS/Nixpkgs repositories, using mirrors for faster access in China.
    # url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-26.05&shallow=1";
    # url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";
    # https://github.com/NixOS/nixpkgs
    # https://wiki.nixos.org/wiki/FAQ#Using_flakes
    nixpkgs-2605 = {
      url = "github:NixOS/nixpkgs/nixos-26.05";
    };
    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nixpkgs-stable.follows = "nixpkgs-2605";
    nixpkgs.follows = "nixpkgs-unstable";

    # Upstream inputs:
    # nix-packages
    # ├── nixpkgs
    # └── nixpkgs-2605-darwin
    #
    # Follow policy: partial — lightweight wrappers share the root unstable package
    # set; the unique x86_64-darwin compatibility pin remains upstream.
    nix-packages = {
      url = "github:sshawn9/nix-packages";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Upstream inputs:
    # nixos-hardware
    # └── nixpkgs
    #
    # Follow policy: all — only hardware modules are consumed, so they should evaluate
    # with the same package set as the host instead of carrying an unused pin.
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Upstream inputs:
    # nix-darwin
    # └── nixpkgs
    #
    # Follow policy: all — the system module framework must share the host package set;
    # there is no cache-sensitive standalone package to preserve.
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Upstream inputs:
    # home-manager
    # └── nixpkgs
    #
    # Follow policy: all — Home Manager modules must use the host package set, avoiding
    # duplicate packages and nixpkgs-version mismatches.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Upstream inputs:
    # flake-parts
    # └── nixpkgs-lib
    #
    # Follow policy: all — this is evaluation-only infrastructure, so sharing the root
    # library removes a duplicate input without affecting binary-cache paths.
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-unstable";
    };

    # Upstream inputs:
    # haumea
    # └── nixpkgs (nixpkgs.lib)
    #
    # Follow policy: all — Haumea only needs lib during evaluation; no build output or
    # upstream cache identity depends on its own pin.
    haumea = {
      url = "github:nix-community/haumea";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Upstream inputs:
    # treefmt-nix
    # └── nixpkgs
    #
    # Follow policy: all — formatter checks and wrappers are local infrastructure, so a
    # shared nixpkgs is more valuable than preserving their inexpensive build paths.
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Upstream inputs:
    # treefmt-preset
    # ├── flake-parts
    # │   └── nixpkgs-lib (shared with treefmt-preset/nixpkgs)
    # ├── nixpkgs
    # └── treefmt-nix
    #     └── nixpkgs (shared with treefmt-preset/nixpkgs)
    #
    # Follow policy: all — every dependency already exists at the root and is used only
    # to assemble this repository's formatting checks.
    treefmt-preset = {
      url = "github:sshawn9/treefmt-preset";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    # Upstream inputs:
    # t2fanrd
    # └── nixpkgs
    #
    # Follow policy: all — its NixOS module should use the host package set, and the
    # small daemon has no cache-sensitive upstream package graph to retain.
    t2fanrd = {
      url = "github:GnomedDev/T2FanRD";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Upstream inputs:
    # noctalia
    # ├── nixpkgs
    # └── noctalia-qs
    #     ├── nixpkgs (shared with noctalia/nixpkgs)
    #     ├── systems
    #     └── treefmt-nix
    #         └── nixpkgs (shared with noctalia/noctalia-qs/nixpkgs)
    #
    # Follow policy: partial — the runtime graph stays upstream for Noctalia's Cachix;
    # only its formatting-only treefmt-nix input is shared with the root.
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell/v4.7.7";
      inputs.noctalia-qs = {
        inputs.treefmt-nix.follows = "treefmt-nix";
      };
    };

    # Upstream inputs:
    # bluetooth-auth
    # ├── flake-parts
    # │   └── nixpkgs-lib (shared with bluetooth-auth/nixpkgs)
    # ├── nixpkgs
    # ├── pyproject-build-systems
    # │   ├── nixpkgs (shared with bluetooth-auth/nixpkgs)
    # │   ├── pyproject-nix (shared with bluetooth-auth/pyproject-nix)
    # │   └── uv2nix (shared with bluetooth-auth/uv2nix)
    # ├── pyproject-nix
    # │   └── nixpkgs (shared with bluetooth-auth/nixpkgs)
    # └── uv2nix
    #     ├── nixpkgs (shared with bluetooth-auth/nixpkgs)
    #     └── pyproject-nix (shared with bluetooth-auth/pyproject-nix)
    #
    # Follow policy: partial — common nixpkgs and flake-parts inputs are shared; the
    # Python-specific toolchain remains upstream because it has no root counterpart.
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

    # Upstream inputs:
    # claude-code-nix
    # ├── nixpkgs
    # └── systems
    #
    # Follow policy: partial — nixpkgs is shared because rebuilding the fixed upstream
    # binary's thin wrapper is cheap; the unique systems input has no root counterpart.
    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Upstream inputs:
    # nix-index-database
    # └── nixpkgs
    #
    # Follow policy: all — the database is pre-generated and its wrapper is cheap;
    # upstream also recommends sharing nixpkgs with the consuming configuration.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Upstream inputs:
    # catppuccin
    # └── nixpkgs
    #
    # Follow policy: none — the modules use Catppuccin's own packages and this repository
    # enables catppuccin.cachix.org, so its upstream package paths must remain intact.
    catppuccin = {
      url = "github:catppuccin/nix";
    };

    # Upstream inputs:
    # sops-nix
    # └── nixpkgs
    #
    # Follow policy: all — its NixOS and Home Manager modules must integrate with the
    # host package set; the helper build is not costly enough to justify another pin.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Upstream inputs:
    # rust-overlay
    # └── nixpkgs
    #
    # Follow policy: all — an overlay is evaluated against the target package set and
    # has no standalone binary-cache identity worth preserving.
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Upstream inputs:
    # openfang
    # ├── flake-parts
    # │   └── nixpkgs-lib
    # ├── nixpkgs
    # └── rust-flake
    #     ├── crane
    #     ├── nixpkgs
    #     └── rust-overlay
    #         └── nixpkgs (shared with openfang/rust-flake/nixpkgs)
    #
    # Follow policy: partial — every dependency with a root counterpart is shared, while
    # rust-flake's unique crane pin remains upstream. OpenFang has no upstream binary
    # cache and is patched locally, so there is no package path to preserve.
    openfang = {
      url = "github:RightNow-AI/openfang/v0.6.9";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-parts.follows = "flake-parts";
      inputs.rust-flake = {
        inputs.nixpkgs.follows = "nixpkgs-unstable";
        inputs.rust-overlay.follows = "rust-overlay";
      };
    };

    # Upstream inputs:
    # nix-cachyos-kernel
    # ├── flake-compat (source only)
    # ├── flake-parts
    # │   └── nixpkgs-lib
    # └── nixpkgs
    #
    # Follow policy: none — the release branch and pinned nixpkgs are a cache-matched
    # unit; upstream warns that overriding nixpkgs loses the kernel cache and can
    # introduce patch/version mismatches.
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # Upstream inputs:
    # mousehop
    # ├── nixpkgs
    # └── rust-overlay
    #     └── nixpkgs (shared with mousehop/nixpkgs)
    #
    # Follow policy: none — the Rust package is consumed directly and this repository
    # enables mousehop.cachix.org; following either input would change its store path.
    mousehop = {
      url = "github:jondkinney/mousehop/v0.14.2";
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
      # inputs.rust-overlay.follows = "rust-overlay";
    };
  };
}
