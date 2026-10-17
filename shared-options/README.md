# Shared Options

Modules in this directory define options used by NixOS, nix-darwin, and
Home Manager. The flake output constructors load these modules in each
evaluation, including embedded and standalone Home Manager.

## Package Selection

[`packages.nix`](./packages.nix) defines `my.packages.<name>` and the package
entry type. Each system and Home Manager evaluation maintains its own package
selections.

Installation is handled by modules in the existing recursive loading paths:

- [`modules/common/utils/packages.nix`](../modules/common/utils/packages.nix) adds enabled
  entries to `environment.systemPackages` for NixOS and nix-darwin.
- [`home-manager/common/utils/packages.nix`](../home-manager/common/utils/packages.nix)
  adds enabled entries to `home.packages` for embedded and standalone
  Home Manager.

Application modules assign `my.packages` directly:

```nix
my.packages = {
  curl = true;
  wget = false;
};
```

A boolean is shorthand for the entry's `enable` option. Attribute sets expose
`enable` and `package`, and declared entries default to disabled. Set `enable`
explicitly when specifying a package to install:

```nix
my.packages.python = {
  enable = true;
  package = pkgs.python3;
};
```

Entry names are flat logical names. Use `package` explicitly for aliases,
such as `python` selecting `pkgs.python3`, or for nested package attributes.
Without an explicit package, the name resolves from `pkgs.unstable` when
available, otherwise from `pkgs`.

Shared modules use `lib.mkDefault` so host and user selections can override
their baseline:

```nix
# Shared module:
my.packages.curl = lib.mkDefault true;
my.packages.wget = lib.mkDefault false;

# Host or user module:
my.packages.curl = false;
my.packages.wget = true;
```

For entries with a custom default package, place defaults on the individual
fields so a host's boolean selection keeps the package choice:

```nix
my.packages.python = {
  enable = lib.mkDefault false;
  package = lib.mkDefault (pkgs.unstable or pkgs).python3;
};
```

An empty entry `{ }` or an entry with only `package` is disabled by default.
Write `true` or `enable = true` to enable it. Disabled entries do not resolve
their package for installation. Other modules can inspect the normalized
`config.my.packages.<name>.enable` and `.package` fields.
