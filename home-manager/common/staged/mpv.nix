{
  lib,
  pkgs,
  ...
}:
{
  programs.mpv = {
    defaultProfiles = [ "high-quality" ];

    scripts = with pkgs.mpvScripts; [
      mpris
      uosc
      thumbfast
    ];
    config = {
      osc = false;
      osd-bar = false;
      border = false;
      force-window = true;

      slang = "zh-CN,zh-Hans,chi,zho,zh,en,eng";
      alang = "zh-CN,zh-Hans,chi,zho,zh,en,eng";

      screenshot-format = "png";
      screenshot-directory = "~/Pictures/Screenshots";

      cache = true;
      cache-on-disk = false;
      cache-secs = 3600000;
      demuxer-max-bytes = "16384MiB";
      demuxer-max-back-bytes = "4096MiB";
      demuxer-seekable-cache = true;
      demuxer-cache-wait = false;
      cache-pause-initial = false;
      demuxer-hysteresis-secs = 0;
      prefetch-playlist = true;

      audio-buffer = 1;
      video-sync = "display-resample";
      interpolation = true;
    };

    bindings = {
      "RIGHT" = "seek  5 exact";
      "LEFT" = "seek -5 exact";

      "UP" = "add volume  5";
      "DOWN" = "add volume -5";

      "Alt+RIGHT" = "seek  30";
      "Alt+LEFT" = "seek -30";

      "Shift+RIGHT" = "seek  120";
      "Shift+LEFT" = "seek -120";

      "[" = "playlist-prev";
      "]" = "playlist-next";

      "p" = "script-binding uosc/items";
      "o" = "script-binding uosc/open-file";
      "m" = "script-binding uosc/menu";
      "t" = "script-message-to uosc toggle-elements timeline";

      "SPACE" = "cycle pause";
      "f" = "cycle fullscreen";
      "s" = "screenshot";
    };
  };
}
