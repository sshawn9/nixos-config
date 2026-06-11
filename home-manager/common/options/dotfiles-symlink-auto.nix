{
  config,
  lib,
  pkgs,
  ...
}:

let
  cleanRelPath = path: lib.removePrefix "/" (toString path);

  relJoin =
    parent: child:
    if parent == "" then
      child
    else if child == "" then
      parent
    else
      "${parent}/${child}";

  joinPath =
    root: path:
    let
      relPath = cleanRelPath path;
    in
    if relPath == "" then root else root + "/${relPath}";

  layerDirs = [
    config.my.paths.dotfilesLayers.baseDir
  ]
  ++ config.my.paths.dotfilesLayers.overrideDirs;

  layerRelPath = dir: path: relJoin dir (cleanRelPath path);

  xdgConfigRelPath = path: relJoin ".config" (cleanRelPath path);

  xdgDataRelPath = path: relJoin ".local/share" (cleanRelPath path);

  targetPath =
    paths: dir: path:
    paths.dotfilesPath (layerRelPath dir path);

  candidatePaths =
    _targetPaths: path:
    map (dir: {
      layerDir = dir;
      store = targetPath config.my.paths.store dir path;
    }) layerDirs;

  existingPaths =
    targetPaths: path:
    lib.filter (candidate: builtins.pathExists candidate.store) (candidatePaths targetPaths path);

  collectFiles =
    storeRoot: targetRoot:
    let
      go =
        relPath:
        let
          storePath = joinPath storeRoot relPath;
          targetSourcePath = joinPath targetRoot relPath;
        in
        if builtins.readFileType storePath == "directory" then
          lib.concatMapAttrs (name: _: go (relJoin relPath name)) (builtins.readDir storePath)
        else
          {
            ${relPath} = targetSourcePath;
          };
    in
    go "";

  layeredFileMap =
    targetPaths: path:
    lib.foldl' (
      acc: dir:
      let
        storeSourcePath = targetPath config.my.paths.store dir path;
        targetSourcePath = targetPath targetPaths dir path;
      in
      if builtins.pathExists storeSourcePath then
        acc // collectFiles storeSourcePath targetSourcePath
      else
        acc
    ) { } layerDirs;

  symlinkCommand = relPath: sourcePath: ''
    mkdir -p "$out"/${lib.escapeShellArg (builtins.dirOf relPath)}
    ln -s -- ${lib.escapeShellArg (toString sourcePath)} "$out"/${lib.escapeShellArg relPath}
  '';

  directorySource =
    sourceName: targetPaths: path:
    let
      relPath = cleanRelPath path;
      files = layeredFileMap targetPaths relPath;
      name =
        if relPath == "" then "root" else builtins.replaceStrings [ "/" "." " " ] [ "-" "_" "-" ] relPath;
    in
    pkgs.runCommandLocal "dotfiles-layered-${sourceName}-${name}" { } ''
      mkdir -p "$out"
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList symlinkCommand files)}
    '';

  sourcePath =
    targetPaths: path:
    let
      matches = existingPaths targetPaths path;
    in
    if matches == [ ] then
      throw "No dotfiles path found for '${cleanRelPath path}' under .dotfiles/${config.my.paths.dotfilesLayers.baseDir} or configured override layers"
    else
      lib.last matches;

  mkLayeredSource =
    sourceName: targetPaths: dotfilesSource: path:
    let
      relPath = cleanRelPath path;
      candidate = sourcePath targetPaths relPath;
      sourceRelPath = layerRelPath candidate.layerDir relPath;
    in
    if builtins.readFileType candidate.store == "directory" then
      directorySource sourceName targetPaths relPath
    else
      dotfilesSource sourceRelPath;

  mkLayeredTree = layeredSource: path: {
    source = layeredSource path;
    recursive = true;
  };

  mkLayeredSources = sourceName: targetPaths: sources: rec {
    dotfilesLayeredSource = path: mkLayeredSource sourceName targetPaths sources.dotfilesSource path;

    xdgConfigLayeredSource = path: dotfilesLayeredSource (xdgConfigRelPath path);

    xdgDataLayeredSource = path: dotfilesLayeredSource (xdgDataRelPath path);

    dotfilesLayeredTree = mkLayeredTree dotfilesLayeredSource;

    xdgConfigLayeredTree = mkLayeredTree xdgConfigLayeredSource;

    xdgDataLayeredTree = mkLayeredTree xdgDataLayeredSource;
  };

  mkSourceOption =
    default: description:
    lib.mkOption {
      type = lib.types.functionTo lib.types.path;
      inherit default description;
    };

  mkTreeOption =
    default: description:
    lib.mkOption {
      type = lib.types.functionTo lib.types.attrs;
      inherit default description;
    };

  mkLayeredOptions = defaults: rootName: {
    dotfilesLayeredSource = mkSourceOption defaults.dotfilesLayeredSource ''
      Build a layered Home Manager source for a path under ${rootName}.dotfilesRoot.

      The store root is used to enumerate and classify files during
      evaluation. The selected source target follows ${rootName}.
    '';

    xdgConfigLayeredSource = mkSourceOption defaults.xdgConfigLayeredSource ''
      Build a layered Home Manager source for a path under ${rootName}.xdgConfigRoot.
    '';

    xdgDataLayeredSource = mkSourceOption defaults.xdgDataLayeredSource ''
      Build a layered Home Manager source for a path under ${rootName}.xdgDataRoot.
    '';

    dotfilesLayeredTree = mkTreeOption defaults.dotfilesLayeredTree ''
      Build a recursive Home Manager file entry from layered dotfiles sources.
    '';

    xdgConfigLayeredTree = mkTreeOption defaults.xdgConfigLayeredTree ''
      Build a recursive Home Manager file entry from layered XDG config sources.
    '';

    xdgDataLayeredTree = mkTreeOption defaults.xdgDataLayeredTree ''
      Build a recursive Home Manager file entry from layered XDG data sources.
    '';
  };

  storeSources = mkLayeredSources "store" config.my.paths.store config.my.paths.store;

  localSources = mkLayeredSources "local" config.my.paths.local config.my.paths.local;
in
{
  options.my.paths.store = mkLayeredOptions storeSources "my.paths.store";

  options.my.paths.local = mkLayeredOptions localSources "my.paths.local";
}
