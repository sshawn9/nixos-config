{
  config,
  lib,
  ...
}:

let
  mkPathSet = repoRoot: rec {
    inherit repoRoot;

    dotfilesRoot = repoRoot + "/.dotfiles";
    xdgConfigRoot = dotfilesRoot + "/.config";
    xdgDataRoot = dotfilesRoot + "/.local/share";

    dotfilesPath = path: dotfilesRoot + "/${path}";
    xdgConfigPath = path: xdgConfigRoot + "/${path}";
    xdgDataPath = path: xdgDataRoot + "/${path}";
  };

  storeDefaults = mkPathSet config.my.paths.store.repoRoot;
  localDefaults = mkPathSet config.my.paths.local.repoRoot;

  mkValueOption =
    type: default: description:
    lib.mkOption {
      inherit type default description;
    };

  mkPathFnOption =
    default: description:
    lib.mkOption {
      type = lib.types.functionTo lib.types.path;
      inherit default description;
    };

  mkStringFnOption =
    default: description:
    lib.mkOption {
      type = lib.types.functionTo lib.types.str;
      inherit default description;
    };
in
{
  options.my.paths.store = {
    dotfilesRoot = mkValueOption lib.types.path storeDefaults.dotfilesRoot ''
      Dotfiles root under the flake source copy in /nix/store.
    '';

    xdgConfigRoot = mkValueOption lib.types.path storeDefaults.xdgConfigRoot ''
      XDG config root under the flake source copy in /nix/store.
    '';

    xdgDataRoot = mkValueOption lib.types.path storeDefaults.xdgDataRoot ''
      XDG data root under the flake source copy in /nix/store.
    '';

    dotfilesPath = mkPathFnOption storeDefaults.dotfilesPath ''
      Build a path inside my.paths.store.dotfilesRoot.
    '';

    xdgConfigPath = mkPathFnOption storeDefaults.xdgConfigPath ''
      Build a path inside my.paths.store.xdgConfigRoot.
    '';

    xdgDataPath = mkPathFnOption storeDefaults.xdgDataPath ''
      Build a path inside my.paths.store.xdgDataRoot.
    '';
  };

  options.my.paths.local = {
    dotfilesRoot = mkValueOption lib.types.str localDefaults.dotfilesRoot ''
      Dotfiles root under the mutable local checkout.
    '';

    xdgConfigRoot = mkValueOption lib.types.str localDefaults.xdgConfigRoot ''
      XDG config root under the mutable local checkout.
    '';

    xdgDataRoot = mkValueOption lib.types.str localDefaults.xdgDataRoot ''
      XDG data root under the mutable local checkout.
    '';

    dotfilesPath = mkStringFnOption localDefaults.dotfilesPath ''
      Build a string path inside my.paths.local.dotfilesRoot.
    '';

    xdgConfigPath = mkStringFnOption localDefaults.xdgConfigPath ''
      Build a string path inside my.paths.local.xdgConfigRoot.
    '';

    xdgDataPath = mkStringFnOption localDefaults.xdgDataPath ''
      Build a string path inside my.paths.local.xdgDataRoot.
    '';
  };
}
