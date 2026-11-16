{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.fileSources.local.xdgConfig) link;
in
{
  config = lib.mkIf config.features.programs.enable {
    xdg.configFile."mise/config.toml" = lib.mkIf config.programs.mise.enable (link "mise/config.toml");

    xdg.configFile."mise/install-python-wheels.sh" = lib.mkIf config.programs.mise.enable (
      link "mise/install-python-wheels.sh"
    );

    xdg.configFile."uv/uv.toml" = lib.mkIf config.programs.uv.enable (link "uv/uv.toml");

    programs = {
      devenv = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.devenv;
      };
      direnv = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.direnv;
        nix-direnv = {
          enable = lib.mkDefault true;
          package = lib.mkDefault pkgs.unstable.nix-direnv;
        };
      };
      mise = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.mise;
      };
      uv = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.uv;
      };
    };
  };
}
