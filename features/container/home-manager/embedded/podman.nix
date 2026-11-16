{
  config,
  lib,
  pkgs,
  ...
}:
let
  podmanContext = {
    Name = "podman";
    Metadata.Description = "Podman Context (Managed by Nix)";
    Endpoints.docker = {
      Host = "unix:///run/user/1000/podman/podman.sock";
      SkipTLSVerify = false;
    };
  };
  podmanHash = builtins.hashString "sha256" podmanContext.Name;

  configDirectory =
    if config.programs.docker-cli.enable then config.programs.docker-cli.configDir else ".docker";
in
{
  config = lib.mkIf config.features.container.enable {
    home.file = lib.mkIf config.services.podman.enable {
      "${configDirectory}/contexts/meta/${podmanHash}/meta.json".text = builtins.toJSON podmanContext;
    };

    services.podman = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.podman;
      settings.storage.storage.driver = lib.mkDefault "overlay";
    };

    package.podman-compose.enable = lib.mkDefault config.services.podman.enable;
  };
}
