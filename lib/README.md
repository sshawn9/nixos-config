# Lib

This directory contains small, repo-specific helpers shared by NixOS,
nix-darwin, standalone Home Manager, and flake output code.

The public entrypoint is [`default.nix`](./default.nix). Import it once and use
the returned attrset as `myLib`.

```nix
myLib = import ./lib { inherit inputs; };
```

## Files

- [`loader.nix`](./loader.nix): module path discovery helpers backed by haumea.
- [`mk-packages.nix`](./mk-packages.nix): package enable-option helpers for
  `home.packages` and `environment.systemPackages`.
- [`module-context.nix`](./module-context.nix): runtime-target detection
  helper for modules shared between NixOS, nix-darwin, and Home Manager.
- [`default.nix`](./default.nix): public export surface for this directory.

## Public API

`default.nix` exposes both grouped namespaces and the common helpers directly:

```nix
myLib.loader.loadShallowModulePathList
myLib.mkPackages.mkHomePackages

myLib.loadAsModulesShallow
myLib.mkHomePackages
```

### Module Loaders

Canonical helpers:

```nix
loadRecursiveModulePathAttrs
loadShallowModulePathAttrs
loadRecursiveModulePathList
loadShallowModulePathList
```

Compatibility aliases used by existing modules:

```nix
loadModules = loadRecursiveModulePathAttrs;
loadModulesShallow = loadShallowModulePathAttrs;
loadAsModules = loadRecursiveModulePathList;
loadAsModulesShallow = loadShallowModulePathList;
```

Typical use:

```nix
imports = myLib.loadAsModulesShallow ./.;
```

`loadAsModulesShallow` is the usual helper for a directory `default.nix`: it
loads immediate child modules, collapses child directories to their
`default.nix`, and excludes the current directory's own `default.nix`.

Use `loadRecursiveModulePathAttrs` when flake output code needs keyed access to
the discovered tree:

```nix
repoTree = myLib.loadModules self.outPath;
repoTree.systems.${system}.${hostname}.default
```

### Package Options

Public helpers:

```nix
mkHomePackages
mkSystemPackages
```

`mkHomePackages` is for Home Manager modules. It generates options under
`my.home.package` and writes enabled packages to `home.packages`.

```nix
imports = [
  (myLib.mkHomePackages {
    ripgrep = { enable = true; };
    fd = { };
    nvtopPackages.full = { };
    custom-tool = { pkg = pkgs.custom-tool; };
  })
];

my.home.package.fd.enable = true;
```

`mkSystemPackages` is for NixOS and nix-darwin modules. It generates options
under `my.system.package` and writes enabled packages to
`environment.systemPackages`.

```nix
imports = [
  (myLib.mkSystemPackages {
    smartmontools = { };
    btrfs-progs = { enable = true; };
  })
];

my.system.package.smartmontools.enable = true;
```

Package catalog leaves support these forms:

```nix
{
  ripgrep = { };
  fd = { enable = true; description = "fd file finder"; };
  custom-tool = { pkg = pkgs.custom-tool; };
  direct = pkgs.direct-package;
}
```

An empty leaf such as `ripgrep = { };` resolves by path from `pkgs.unstable` when
available, otherwise from `pkgs`. Nested leaves work the same way:

```nix
nvtopPackages.full = { };
# => pkgs.unstable.nvtopPackages.full or pkgs.nvtopPackages.full
```

If the option name should not match the package path, use explicit `pkg`.

Internal package helpers are intentionally not exported from `default.nix`.
Keeping the public surface to `mkHomePackages` and `mkSystemPackages` makes the
package catalog easy to change without creating a larger API contract.

### Module Context

Public helper:

```nix
moduleContext
```

`moduleContext` derives mutually exclusive boolean flags from a module's
arguments to identify which runtime target the current evaluation is. Use it
in modules that are shared between NixOS, nix-darwin, embedded Home Manager,
and standalone Home Manager but need to branch on the framework.

```nix
{ config, osConfig ? null, pkgs, lib, myLib, ... }:
let
  ctx = myLib.moduleContext { inherit config osConfig pkgs; };
in
{
  config = lib.mkMerge [
    (lib.mkIf ctx.isStandaloneHM { /* standalone-HM-only */ })
    (lib.mkIf ctx.isEmbeddedHM   { /* embedded-HM-only */ })
    (lib.mkIf ctx.isNixOS        { /* NixOS-only */ })
    (lib.mkIf ctx.isDarwin       { /* darwin-only */ })
  ];
}
```

The helper returns:

```nix
{
  isHomeManager  = bool;  # config ? home
  isEmbeddedHM   = bool;  # HM under NixOS / nix-darwin (osConfig is set)
  isStandaloneHM = bool;  # HM via homeConfigurations.<key>
  isNixOS        = bool;  # NixOS system module
  isDarwin       = bool;  # nix-darwin system module
}
```

Caller contract: the consuming module must declare `osConfig ? null` (with
the default) in its argument list, otherwise non-embedded-HM evaluations fail
on a missing argument. Detection principles and the truth table are
documented at the top of [`module-context.nix`](./module-context.nix).

## Documentation Convention

Public helpers should use this comment shape:

```nix
# functionName
# Scope:   universal | nixos | darwin | home-manager | flake | lib
# Returns: exact return shape
# Use:     intended call site
# Notes:   important edge cases or hidden behavior
# Example:
#   concrete input/output sketch
```

Scope labels:

- `universal`: Safe in NixOS modules, nix-darwin modules, standalone Home
  Manager modules, flake outputs, and plain lib code.
- `nixos`: NixOS module scope only.
- `darwin`: nix-darwin module scope only.
- `home-manager`: Home Manager module scope, including standalone Home Manager.
- `flake`: Flake output construction scope.
- `lib`: Plain helper code with no module-system dependency.
