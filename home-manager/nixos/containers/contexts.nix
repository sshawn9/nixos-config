{
  config,
  lib,
  ...
}:

let
  podmanHash = builtins.hashString "sha256" "podman";
  dockerHash = builtins.hashString "sha256" "docker-rootless";
in
{
  home.file = lib.mkIf config.my.shared.containers.enable {
    ".docker/contexts/meta/${podmanHash}/meta.json".text = builtins.toJSON {
      Name = "podman";
      Metadata = {
        Description = "Podman Context (Managed by Nix)";
      };
      Endpoints.docker = {
        Host = "unix:///run/user/1000/podman/podman.sock";
        SkipTLSVerify = false;
      };
    };

    ".docker/contexts/meta/${dockerHash}/meta.json".text = builtins.toJSON {
      Name = "docker-rootless";
      Metadata = {
        Description = "Docker Rootless Context (Managed by Nix)";
      };
      Endpoints.docker = {
        Host = "unix:///run/user/1000/docker.sock";
        SkipTLSVerify = false;
      };
    };
  };
}
