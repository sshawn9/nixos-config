{
  lib,
  pkgs,
  config,
  ...
}:

{
  xdg.configFile = lib.mkIf config.programs.mise.enable {
    "mise/config.toml".source = config.my.paths.local.xdgConfigLayeredSource "mise/config.toml";

    "mise/install-python-wheels.sh".source =
      config.my.paths.local.xdgConfigLayeredSource "mise/install-python-wheels.sh";
  };

  programs = {
    mise = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.mise;
    };
  };
}
