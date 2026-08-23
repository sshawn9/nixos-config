{ config, ... }:
let
  inherit (config.my.shared) username;
in
{
  home-manager.users.${username} = {
    home.username = username;

    # The repository is staged beside the generated flake, not in its place.
    my.paths.local.repoRoot = "/etc/nixos/config";
  };
}
