{
  lib,
  config,
  pkgs,
  ...
}:

{
  services.ollama = {
    enable = lib.mkDefault false;

    package = lib.mkDefault (
      if config.my.shared.nvidia.enable then pkgs.unstable.ollama-cuda else pkgs.unstable.ollama
    );

    host = lib.mkDefault "127.0.0.1";
    port = lib.mkDefault 11434;

    loadModels = lib.mkDefault [
    ];
  };
}
