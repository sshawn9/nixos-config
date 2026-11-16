{
  config,
  lib,
  ...
}:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.user-environment.enable {
    xdg = {
      enable = lib.mkDefault true;
      localBinInPath = lib.mkDefault true;
    };
  };
}
