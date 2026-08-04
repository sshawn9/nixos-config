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

        mpv.enable = true;
      };
    };
  };
}
