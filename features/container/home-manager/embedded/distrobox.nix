{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.container.enable {
    programs.distrobox = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.distrobox;
      settings.container_manager = lib.mkDefault "podman";
    };
  };
}
