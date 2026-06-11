{
  config,
  lib,
  ...
}:

let
  mkSourceOption =
    default: description:
    lib.mkOption {
      type = lib.types.functionTo lib.types.path;
      inherit default description;
    };

  mkSources = paths: mkSource: {
    dotfilesSource = path: mkSource (paths.dotfilesPath path);

    xdgConfigSource = path: mkSource (paths.xdgConfigPath path);

    xdgDataSource = path: mkSource (paths.xdgDataPath path);
  };

  mkSourceOptions = sources: rootName: {
    dotfilesSource = mkSourceOption sources.dotfilesSource ''
      Build a Home Manager source for a path under ${rootName}.dotfilesRoot.
    '';

    xdgConfigSource = mkSourceOption sources.xdgConfigSource ''
      Build a Home Manager source for a path under ${rootName}.xdgConfigRoot.
    '';

    xdgDataSource = mkSourceOption sources.xdgDataSource ''
      Build a Home Manager source for a path under ${rootName}.xdgDataRoot.
    '';
  };

  storeSources = mkSources config.my.paths.store (path: path);

  localSources = mkSources config.my.paths.local (path: config.lib.file.mkOutOfStoreSymlink path);
in
{
  options.my.paths.store = mkSourceOptions storeSources "my.paths.store";

  options.my.paths.local = mkSourceOptions localSources "my.paths.local";
}
