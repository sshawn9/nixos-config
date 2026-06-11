{
  config,
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  config = lib.mkIf config.my.shared.desktops.niri.enable {
    programs.noctalia-shell = {
      enable = true;

      settings = config.my.paths.local.xdgConfigLayeredSource "noctalia/settings.json";
      plugins = config.my.paths.local.xdgConfigLayeredSource "noctalia/plugins.json";
    };
  };
}
