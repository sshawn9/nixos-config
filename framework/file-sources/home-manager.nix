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
    in
    lib.mkMerge [
      (lib.mkIf present (
        {
          inherit (resolved) source;
        }
        // lib.optionalAttrs resolved.directory { recursive = lib.mkDefault true; }
        // file
      ))
      (lib.mkIf (!present) { enable = false; })
    ];
in
{
  _class = "homeManager";
  imports = [ ./options.nix ];

  config.lib.fileSources = import ./sources.nix { inherit config lib pkgs; } mkLink;
}
