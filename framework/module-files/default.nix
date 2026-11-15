{ lib, ... }:
{
  options.flake.lib.moduleFiles = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = import ./discovery.nix { inherit lib; };
    description = "Discover Nix module paths as trees or lists without evaluating file contents.";
  };
}
