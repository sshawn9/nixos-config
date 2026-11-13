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
        {
          source =
            if resolved.directory then
              pkgs.linkFarm "file-sources-${resolved.mode}-${resolved.name}" resolved.files
            else
              source resolved.source;
        }
        // lib.optionalAttrs resolved.directory { recursive = lib.mkDefault true; }
        // file
      ))
      (lib.mkIf (!present) { enable = false; })
    ];
in
{
  config.lib.fileSources = import ./sources.nix { inherit config lib; } mkLink;
}
