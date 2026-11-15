{ inputs, lib, ... }:
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = lib.mkDefault (import ./pkgs.nix { inherit inputs; } system);
    };
}
