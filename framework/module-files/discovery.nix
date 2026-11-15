{ lib }:
let
  tree =
    directory:
    let
      entries = lib.filterAttrs (
        name: type:
        !lib.hasPrefix "_" name && (type == "directory" || (type == "regular" && lib.hasSuffix ".nix" name))
      ) (builtins.readDir directory);
    in
    lib.mapAttrs (
      name: type:
      let
        path = directory + "/${name}";
      in
      if type == "directory" then tree path else path
    ) entries;

  list = directory: lib.collect (value: !lib.isAttrs value) (tree directory);
in
{
  inherit tree list;
}
