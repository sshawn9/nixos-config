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
      programs = {
        ghostty.enable = true;

        vscode.enable = true;

        opencode.enable = true;

        mpv.enable = true;

        aria2.enable = true;

        claude-code.enable = true;
        codex.enable = true;
      };
    };
  };
}
