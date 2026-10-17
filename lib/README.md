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
- [`module-context.nix`](./module-context.nix): pure framework-context helper
  for modules shared between NixOS, nix-darwin, and Home Manager.
- [`default.nix`](./default.nix): public export surface for this directory.

## Public API

`default.nix` exposes both grouped namespaces and the common helpers directly:

```nix
myLib.loader.loadShallowModulePathList

myLib.loadShallowModulePathList
myLib.moduleContext
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

### Module Context

Call the public helper with the module's argument set:

```nix
myLib.moduleContext args
```

`moduleContext` is a pure function that reads the built-in `_class` argument
and `specialArgs.osClass`, which Home Manager supplies when embedded in a
system. Capture the argument set with `args@` and pass it directly:

```nix
args@{ lib, myLib, ... }:
let
  context = myLib.moduleContext args;
in
{
  imports =
    lib.optionals context.inNixOSProper [ ./nixos.nix ]
    ++ lib.optionals context.inDarwinProper [ ./darwin.nix ]
    ++ lib.optionals context.inHomeManager [ ./home-manager.nix ];
}
```

The module system includes `_class` and `specialArgs` in `args` even when
they are not explicitly named in the module's parameter list. The helper
does not read `config`, `osConfig`, or `pkgs`. The repository supplies
`myLib` through `specialArgs` / `extraSpecialArgs`, so the helper is
available while resolving `imports`.

For a single check, access the result directly:

```nix
args@{ myLib, ... }:
{
  my.packages.git = (myLib.moduleContext args).inHomeManager;
}
```

The result contains these boolean fields:

| Field            | Meaning                                           |
| ---------------- | ------------------------------------------------- |
| `inHomeManager`  | Any Home Manager evaluation                       |
| `inEmbeddedHM`   | Home Manager with a non-null `osClass`            |
| `inStandaloneHM` | Home Manager with an absent or null `osClass`     |
| `inNixOSProper`  | The NixOS system evaluation                       |
| `inDarwinProper` | The nix-darwin system evaluation                  |
| `inNixOSSystem`  | NixOS or Home Manager embedded in NixOS           |
| `inDarwinSystem` | nix-darwin or Home Manager embedded in nix-darwin |

The flags overlap: a NixOS system evaluation sets both `inNixOSProper`
and `inNixOSSystem`. A null or unrecognized `_class` sets all fields to
`false`.

Framework membership is independent of the target platform. Standalone
Home Manager remains standalone even when run on a NixOS machine. Use
`pkgs.stdenv.hostPlatform` for platform checks in configuration values, or
`lib.systems.elaborate system` for import selection when `system` is
provided through `specialArgs`.

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
