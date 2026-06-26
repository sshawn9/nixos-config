{
  lib,
  pkgs,
  config,
  ...
}:

{
  xdg.configFile."uv/uv.toml" = lib.mkIf config.programs.uv.enable {
    source = config.my.paths.local.xdgConfigLayeredSource "uv/uv.toml";
  };

  programs = {
    uv = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.uv;
    };
  };
}
