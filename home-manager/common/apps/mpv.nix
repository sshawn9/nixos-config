{
  lib,
  pkgs,
  ...
}:
{
  programs.mpv = {
    enable = lib.mkDefault false;
    scripts = [
      pkgs.mpvScripts.uosc
      pkgs.mpvScripts.thumbfast
    ];
    config = {
      "osc" = "no";
      "osd-bar" = "no";
      "border" = "no";

      "profile" = "gpu-hq";
      "vo" = "gpu-next";
      "hwdec" = "auto-safe";

      "slang" = "chi,zh-CN,sc,zh,eng,en";
      "alang" = "chi,zh-CN,sc,zh,eng,en";

      "screenshot-format" = "png";
      "screenshot-directory" = "~/Pictures/Screenshots";

      "cache" = "yes";
      "demuxer-max-bytes" = "8192MiB";
      "demuxer-max-back-bytes" = "1024MiB";
      "demuxer-seekable-cache" = "yes";
      "prefetch-playlist" = "yes";
      "force-window" = "yes";

      "audio-buffer" = "1";
      "video-sync" = "display-resample";
      "interpolation" = "yes";
      "tscale" = "oversample";
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
