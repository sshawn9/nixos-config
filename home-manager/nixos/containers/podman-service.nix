{
  config,
  lib,
  ...
}:

{
  services.podman = lib.mkIf config.my.shared.containers.enable {
    enable = lib.mkDefault true;

    settings.storage = {
      storage.driver = "overlay";
    };
  };
}
