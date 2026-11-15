{ lib, haumea }:
let
  flatten = lib.collect (value: !lib.isAttrs value);

  recursive = rec {
    attrs =
      directory:
      haumea.load {
        src = directory;
        loader = haumea.loaders.path;
      };
    list = directory: flatten (attrs directory);
  };

  shallow = rec {
    attrs =
      directory:
      lib.mapAttrs (
        name: value:
        if !lib.isAttrs value then
          value
        else if lib.isPath (value.default or null) then
          value.default
        else
          throw "moduleFiles.shallow.attrs: ${toString directory}/${name} is a directory without default.nix"
      ) (recursive.attrs directory);

    # A directory's default.nix can use this without importing itself.
    list = directory: builtins.attrValues (removeAttrs (attrs directory) [ "default" ]);
  };
in
{
  inherit flatten recursive shallow;
}
