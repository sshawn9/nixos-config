{
  config,
  lib,
  ...
}:

{
  services.podman = lib.mkIf config.my.shared.containers.enable {
    enable = true;

    settings.storage = {
      storage.driver = "overlay";
    };
  };
}
