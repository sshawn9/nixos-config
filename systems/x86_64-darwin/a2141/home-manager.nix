{
  config,
  ...
}:
let
  inherit (config.my.shared) username;
in
{
  home-manager = {
    users.${username} = {
      home.username = username;

      programs = {
        claude-code.enable = true;
        vscode.enable = true;
        uv.enable = true;
        mcp.enable = true;
      };

      my = {
        packages = {
          obsidian.enable = true;
          google-chrome.enable = true;
          antigravity.enable = true;
          code-cursor.enable = true;
          sqlite.enable = true;
          sqlitebrowser.enable = true;
          regctl.enable = true;
          skopeo.enable = true;
          rustup.enable = true;
        };
      };
    };
  };
}
