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
      my = {
        packages = {
          nvtop = true;

          ariang = true;

          obsidian = true;
          github-desktop = true;

          google-chrome = true;
          microsoft-edge = true;

          # clion = true;
          # pycharm = true;
          # rust-rover = true;

          telegram-desktop = true;

          ffmpeg-full = true;

          losslesscut = true;

          antigravity-ide = true;
        };
      };
    };
  };
}
