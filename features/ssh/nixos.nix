{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.ssh.enable {
    services.openssh = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.openssh;
    };
  };
}
