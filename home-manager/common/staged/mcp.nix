{
  lib,
  config,
  pkgs,
  ...
}:
let
  npx = lib.getExe' pkgs.unstable.nodejs_latest "npx";
  uvx = lib.getExe' pkgs.unstable.uv "uvx";
in

{
  programs = {
    mcp = {
      enable = lib.mkDefault false;
      servers = {
        everything = {
          command = npx;
          args = [
            "-y"
            "@modelcontextprotocol/server-everything"
          ];
        };

        activitywatch = {
          command = npx;
          args = [
            "-y"
            "activitywatch-mcp-server"
          ];
        };

        basic-memory = {
          command = uvx;
          args = [
            "basic-memory"
            "mcp"
          ];
          env.BASIC_MEMORY_HOME = "${config.home.homeDirectory}/.local/share/basic-memory";
        };
      };
    };
  };
}
