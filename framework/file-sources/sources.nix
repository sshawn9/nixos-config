{ config, lib }:
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

  mkSources =
    mode: root:
    let
      resolve =
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

      scope = prefix: {
        link =
          value:
          let
            file = if builtins.isString value then { source = value; } else value;
            inherit (file) source;
            onMissing = file.onMissing or "error";
            resolved = resolve (join prefix source);
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
          mkLink checked (
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
