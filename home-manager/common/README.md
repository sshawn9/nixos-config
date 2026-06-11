# Home Manager Common

This directory contains Home Manager modules shared by every supported Home
Manager entrypoint:

- embedded Home Manager on NixOS
- embedded Home Manager on nix-darwin
- standalone Home Manager

`home-manager/standalone.nix` and `home-manager/embedded.nix` load this
directory recursively with `myLib.loadRecursiveModulePathList`, so every `.nix`
module under `common/` is part of the shared baseline.

Modules in this directory should avoid depending on Linux-only, NixOS-only, or
Darwin-only options. Platform-specific behavior belongs in
`home-manager/nixos/` or `home-manager/darwin/`.

## Organization

### `options/`

Shared option definitions and path helpers.

This is where shared vocabulary belongs, especially `my.paths.*` options used by
other Home Manager modules:

- repository roots for both the flake store copy and the mutable local checkout
- `.dotfiles`, XDG config, and XDG data roots
- source helpers for store-backed files and out-of-store symlinks
- layered dotfiles helpers based on `base` plus optional override layers

Do not put concrete program configuration or package selections here.

### `utils/`

Small shared defaults and glue modules.

Use this directory for cross-cutting Home Manager behavior that is not a tool
domain by itself, such as:

- `home.stateVersion`
- enabling XDG support
- shared dotfiles mappings
- small integration defaults such as MCP server definitions

If a file starts to own a recognizable tool or application, move it into the
matching domain directory instead.

### `shell/`

The baseline interactive shell experience.

This directory is for tools and settings that make a fresh shell feel ready to
use immediately after login:

- shell setup, such as zsh and nushell
- prompt integration
- completion systems and completion styles
- history, command hints, directory jumping, and fuzzy selection
- session path defaults

If a tool mainly improves command input or shell navigation, it belongs here.
Broader terminal applications usually belong under `cli/`.

### `cli/`

Terminal applications and command-line workflow tools.

Use this directory for tools that are primarily operated from a terminal but are
not part of the shell's core input/completion/history experience, such as:

- tmux and zellij
- SSH configuration
- Nix CLI helpers
- terminal file managers, monitors, search tools, and archive/network utilities

### `git/`

Git and repository workflow configuration.

Put Git, GitHub, repository navigation, and adjacent version-control tools here.

### `apps/`

Cross-platform user applications.

This directory contains application modules that can reasonably participate in
the shared Home Manager baseline, such as Node.js, Claude Code, Obsidian, MPV,
aria2, and general app package toggles.

Linux-only desktop app behavior belongs in `home-manager/nixos/apps/`; Darwin
specific app behavior belongs in `home-manager/darwin/apps/`.

### `editors/`

Editor and IDE modules, such as VS Code and JetBrains tools.

Use this directory for editor-specific packages, `programs.*` configuration, and
editor-related defaults that are shared across supported platforms.

### `python/`

Python tooling shared across hosts, currently centered on `uv`.

Use this directory when the module is specifically about Python development
tooling rather than a general CLI utility.

### `theme/`

Shared theme modules.

This directory is for cross-platform appearance defaults, currently Catppuccin.
Keep platform-specific theme fixes near the platform-specific module when they
depend on NixOS, Linux desktop, or Darwin behavior.

### `containers/`

Shared container-related packages and user-level tooling.

NixOS service definitions, Podman services, and host-specific container runtime
behavior belong under `home-manager/nixos/containers/`.

### `sops/`

Shared Home Manager SOPS integration.

Keep secret wiring here when it is portable across embedded and standalone Home
Manager. Platform-specific service integration should stay under the matching
platform directory.

## Dotfiles Sources

Most modules should use the source helpers exposed under `my.paths.*` instead
of manually constructing repository paths.

Use `config.my.paths.store.*` when evaluation needs a pure flake-store path,
for example to enumerate files or feed a derivation.

Use `config.my.paths.local.*` when Home Manager should create an out-of-store
symlink to the mutable checkout.

For ordinary user config files, prefer the layered helpers:

```nix
xdg.configFile."starship.toml".source =
  config.my.paths.local.xdgConfigLayeredSource "starship.toml";
```

For directories, use the tree helpers:

```nix
xdg.configFile."just" =
  config.my.paths.local.xdgConfigLayeredTree "just";
```

Layered helpers look under `.dotfiles/<base layer>` and then configured override
layers. Later override layers win for the same relative file path.

## Fallback Files

`packages.nix` and `programs.nix` are fallback files inside a domain.

Use `packages.nix` for package enable options that do not yet deserve a more
specific module:

```nix
imports = [
  (myLib.mkHomePackages {
    curl.enable = true;
    unzip.enable = true;
  })
];
```

Use `programs.nix` for Home Manager `programs.*` configuration that does not
yet have a clearer domain or a large enough body to justify its own file.

When a package or program grows meaningful configuration, move it out of the
fallback file into a dedicated module such as:

```text
tmux.nix
zellij.nix
ssh.nix
nix.nix
aria.nix
nodejs.nix
```

## Placement Rules

When adding a new Home Manager module, choose its location in this order:

1. If it defines shared options, paths, or helper functions, put it in
   `options/`.
2. If it is a small cross-cutting default or glue module, put it in `utils/`.
3. If it changes the core shell input experience, put it in `shell/`.
4. If it belongs to an existing common domain, put it in that domain directory.
5. If it starts a new clear domain, create a new top-level domain directory
   under `common/`.
6. If it is a small package toggle inside a domain, add it to that domain's
   `packages.nix`.
7. If it is a small `programs.*` configuration inside a domain, add it to that
   domain's `programs.nix`.
8. If it only works on Linux/NixOS or Darwin, place it under
   `home-manager/nixos/` or `home-manager/darwin/` instead of `common/`.

## Defaults

Common modules should provide a strong default experience while staying easy to
override from host or user modules.

Prefer `lib.mkDefault` for default enables, package choices, and general
settings:

```nix
programs.foo.enable = lib.mkDefault true;
```

Hosts can then override the shared baseline explicitly:

```nix
programs.foo.enable = false;
my.packages.bar.enable = true;
```
