{ config, ... }:

{
  home.file.".codex/AGENTS.md".source = config.my.paths.local.dotfilesLayeredSource "ai/AGENTS.md";

  xdg.configFile."opencode/AGENTS.md".source =
    config.my.paths.local.dotfilesLayeredSource "ai/AGENTS.md";

  xdg.configFile."Code/User/settings.json".source =
    config.my.paths.local.xdgConfigLayeredSource "Code/User/settings.json";

  xdg.configFile."Code/User/extensions.json".source =
    config.my.paths.local.xdgConfigLayeredSource "Code/User/extensions.json";
}
