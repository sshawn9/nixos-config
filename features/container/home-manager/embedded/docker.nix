{
  config,
  lib,
  osConfig,
  ...
}:
let
  rootlessDockerContext = {
    Name = "docker-rootless";
    Metadata.Description = "Docker Rootless Context (Managed by Nix)";
    Endpoints.docker = {
      Host = "unix:///run/user/1000/docker.sock";
      SkipTLSVerify = false;
    };
  };
  dockerHash = builtins.hashString "sha256" rootlessDockerContext.Name;

  configDirectory =
    if config.programs.docker-cli.enable then config.programs.docker-cli.configDir else ".docker";
in
{
  config = lib.mkIf config.features.container.enable {
    home.file = lib.mkIf osConfig.virtualisation.docker.rootless.enable {
      "${configDirectory}/contexts/meta/${dockerHash}/meta.json".text =
        builtins.toJSON rootlessDockerContext;
    };
  };
}
