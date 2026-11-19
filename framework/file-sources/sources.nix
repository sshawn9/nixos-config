{
  config,
  lib,
  pkgs,
}:
mkLink:
let
  cfg = config.fileSources;
  layerDirs = [ cfg.baseDir ] ++ cfg.overrideDirs;

  clean = path: lib.removePrefix "/" (toString path);
  join =
    root: path:
    let
      relative = clean path;
    in
    if root == "" then
      relative
    else if relative == "" then
      root
    else
      root + "/${relative}";

  # Only the snapshot is inspected; local paths need not exist on the builder.
  existingLayers =
    path: lib.filter (layer: builtins.pathExists (join cfg.storeRoot (join layer path))) layerDirs;

  collectFiles =
    storeRoot: targetRoot:
    let
      go =
        relative:
        let
          source = join storeRoot relative;
        in
        if builtins.readFileType source == "directory" then
          lib.concatMapAttrs (name: _: go (join relative name)) (builtins.readDir source)
        else
          { ${relative} = join targetRoot relative; };
    in
    go "";

  mkSource =
    resolved:
    if resolved.directory then
      pkgs.linkFarm "file-sources-${resolved.mode}-${resolved.name}" resolved.files
    else if resolved.mode == "store" then
      resolved.source
    else
      "${pkgs.linkFarm "file-source-local" { inherit (resolved) source; }}/source";

  mkSources =
    mode: root:
    let
      resolvePath =
        path:
        let
          relative = clean path;
          matches = existingLayers relative;
          selected = join (lib.last matches) relative;
          directory = builtins.readFileType (join cfg.storeRoot selected) == "directory";
          files = lib.foldl' (
            acc: layer:
            let
              layerPath = join layer relative;
            in
            acc // collectFiles (join cfg.storeRoot layerPath) (join root layerPath)
          ) { } matches;
          name =
            if relative == "" then "root" else builtins.replaceStrings [ "/" "." " " ] [ "-" "_" "-" ] relative;
        in
        if matches == [ ] then
          null
        else
          {
            inherit
              mode
              directory
              files
              name
              ;
            source = join root selected;
          };

      scope = prefix: rec {
        # Return a usable source and the local directories its links depend on.
        resolve =
          value:
          let
            file = if builtins.isString value then { source = value; } else value;
            inherit (file) source;
            onMissing = file.onMissing or "error";
            resolved = resolvePath (join prefix source);
            message = "fileSources: no source found for '${toString source}'";
            checked =
              if resolved != null then
                resolved
              else
                {
                  ignore = null;
                  warn = lib.warn message null;
                  error = throw message;
                }
                .${onMissing};
          in
          if checked == null then
            null
          else
            {
              source = mkSource checked;
              inherit (checked) directory;
              localDirectories = lib.optionals (mode == "local" && cfg.localRoot != null) (
                lib.unique (
                  map dirOf (if checked.directory then builtins.attrValues checked.files else [ checked.source ])
                )
              );
            };

        link =
          value:
          let
            file = if builtins.isString value then { source = value; } else value;
          in
          mkLink (resolve file) (
            removeAttrs file [
              "source"
              "onMissing"
            ]
          );
      };
    in
    scope ""
    // {
      xdgConfig = scope ".config";
      xdgData = scope ".local/share";
    };

  localRoot =
    if cfg.localRoot == null then
      lib.warn "fileSources.localRoot is null. Local file sources are falling back to the storeRoot snapshot." cfg.storeRoot
    else
      cfg.localRoot;
in
{
  store = mkSources "store" cfg.storeRoot;
  local = mkSources "local" localRoot;
}
