{ lib, ... }:

{
  options.my.shared.containers.enable = lib.mkEnableOption "containers (Podman, Docker, etc.)";
}
