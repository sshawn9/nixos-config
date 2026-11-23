{
  callPackage,
  source,
  configuration,
  offline,
}:
let
  extensions = callPackage ./extensions.nix {
    inherit source configuration offline;
  };
in
callPackage ./package.nix { inherit extensions; }
