{ lib, haumea }:
let
  moduleFiles = import ../framework/module-files/discovery.nix {
    inherit lib haumea;
  };
in
directory:
let
  collectChildren =
    path: files:
    lib.concatLists (
      lib.mapAttrsToList (
        name: child: if lib.isAttrs child then collectFeature (path ++ [ name ]) child else [ ]
      ) files
    );

  collectFeature =
    path: files:
    if
      lib.any (role: builtins.hasAttr role files) [
        "feature"
        "options"
        "nixos"
        "home-manager"
      ]
    then
      [
        {
          inherit path;
          modules =
            map (file: { config.nixos = file; }) (moduleFiles.flatten (files.nixos or { }))
            ++ map (file: { config.homeManager = file; }) (moduleFiles.flatten (files.home-manager or { }))
            ++ map (file: {
              _file = toString file;
              config.options = file;
            }) (moduleFiles.flatten (files.options or { }))
            ++ moduleFiles.flatten (files.feature or { });
        }
      ]
    else
      collectChildren path files;
in
collectChildren [ ] (moduleFiles.recursive.attrs directory)
