{
  config,
  ...
}:

{
  xdg.configFile."gpu-screen-recorder/config_ui".source =
    config.my.paths.local.xdgConfigLayeredSource "gpu-screen-recorder/config_ui";
}
