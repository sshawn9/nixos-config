{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkLink =
    resolved: file:
    let
      present = resolved != null;
      source =
        path:
        if resolved.mode == "store" then
          path
        else
          "${pkgs.linkFarm "file-source-local" { source = path; }}/source";
    in
    lib.mkMerge [
      (lib.mkIf present (
        (
          if resolved.directory then
            { _fileSourcesFiles = lib.mapAttrs (_: source) resolved.files; }
          else
            { source = source resolved.source; }
        )
        // file
      ))
      (lib.mkIf (!present) { enable = false; })
    ];
in
{
  config.lib.fileSources = import ./sources.nix { inherit config lib; } mkLink;

  options.environment.etc = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options._fileSourcesFiles = lib.mkOption {
          type = lib.types.nullOr (lib.types.attrsOf lib.types.path);
          default = null;
          internal = true;
        };
      }
    );
    apply = lib.concatMapAttrs (
      name: file:
      if file._fileSourcesFiles == null then
        { ${name} = file; }
      else
        lib.mapAttrs' (relative: source: {
          # Distinct keys leave duplicate targets to NixOS's native handling.
          name = "fileSources:${
            builtins.toJSON [
              name
              relative
            ]
          }";
          value = removeAttrs file [ "_fileSourcesFiles" ] // {
            inherit source;
            target = "${file.target}/${relative}";
          };
        }) file._fileSourcesFiles
    );
  };
}
