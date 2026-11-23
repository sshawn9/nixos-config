{ inputs, withSystem, ... }:
{
  flake.lib.mkNixosSystem = import ./mk-nixos-system.nix { inherit inputs withSystem; };
}
