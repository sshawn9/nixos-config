{ lib, system, ... }:

{
  # The host directory under systems/<system>/ already names the platform, and
  # mkSystem passes it in, so no host has to restate it.
  nixpkgs.hostPlatform = lib.mkDefault system;
}
