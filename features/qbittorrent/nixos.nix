{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.features.qbittorrent;
  # Forward definitions before apply, at mkDefault priority.
  defaults = lib.mapAttrs (
    _: option: lib.modules.mkAliasAndWrapDefsWithPriority lib.id (option // { highestPrio = 1000; })
  ) options.features.qbittorrent;
in
{
  imports = [ ./options.nix ];

  config = {
    networking.firewall = {
      allowedTCPPorts = [ cfg.peerPort ];
      allowedUDPPorts = [ cfg.peerPort ];
    };
  }
  // lib.optionalAttrs (options ? home-manager.sharedModules) {
    home-manager.sharedModules = [
      (
        { options, ... }:
        {
          # Only users importing the HM module receive these defaults.
          config = lib.optionalAttrs (options ? features.qbittorrent) {
            features.qbittorrent = defaults;
          };
        }
      )
    ];
  };
}
