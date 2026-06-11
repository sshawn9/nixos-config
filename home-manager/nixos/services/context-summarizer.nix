{
  config,
  lib,
  pkgs,
  repoTree,
  ...
}:

let
  cfg = config.my.services.context-summarizer;

  summarizer = pkgs.callPackage repoTree.packages.context-summarizer.default { };

  atuinBin = "${config.programs.atuin.package or pkgs.atuin}/bin/atuin";

  resolvedScreenpipeUrl =
    if cfg.screenpipeUrl != null then
      cfg.screenpipeUrl
    else if config.my.services.screenpipe.enable or false then
      "http://127.0.0.1:${toString config.my.services.screenpipe.port}"
    else
      null;

  resolvedScreenpipeBin =
    if config.my.services.screenpipe.enable or false then
      lib.getExe config.my.services.screenpipe.package
    else
      null;
in
{
  options.my.services.context-summarizer = {
    enable = lib.mkEnableOption "Hourly AI context summary writer";

    interval = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "systemd OnCalendar expression for the timer.";
    };

    lookbackSec = lib.mkOption {
      type = lib.types.ints.positive;
      default = 3600;
      description = "Seconds of history each run should summarize.";
    };

    outputDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.local/share/basic-memory";
      description = ''
        Directory to append `_Current_Context.md` into. Replace with an
        Obsidian vault path when one is chosen.
      '';
    };

    activityWatchUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:5600";
      description = "ActivityWatch REST base URL.";
    };

    ollamaUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:11434";
      description = "Ollama API base URL.";
    };

    ollamaModel = lib.mkOption {
      type = lib.types.str;
      default = "qwen3.5:9b";
      description = "Ollama model tag for the summary.";
    };

    screenpipeUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Screenpipe REST base URL, e.g. http://127.0.0.1:3030. Null skips
        Screenpipe data collection (the summary degrades gracefully).
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Optional EnvironmentFile for the systemd user service. Useful for
        secrets such as CONTEXT_SUMMARIZER_SCREENPIPE_TOKEN when Screenpipe is
        remote or auto token discovery is not desired.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.context-summarizer = {
      Unit.Description = "Append a Markdown activity summary to _Current_Context.md";
      Service = {
        Type = "oneshot";

        ExecStart = "${lib.getExe summarizer}";

        Environment = [
          "CONTEXT_SUMMARIZER_OUTPUT_DIR=${cfg.outputDir}"
          "CONTEXT_SUMMARIZER_LOOKBACK_SEC=${toString cfg.lookbackSec}"
          "CONTEXT_SUMMARIZER_AW_URL=${cfg.activityWatchUrl}"
          "CONTEXT_SUMMARIZER_OLLAMA_URL=${cfg.ollamaUrl}"
          "CONTEXT_SUMMARIZER_OLLAMA_MODEL=${cfg.ollamaModel}"
          "CONTEXT_SUMMARIZER_ATUIN_BIN=${atuinBin}"
        ]
        ++ lib.optional (
          resolvedScreenpipeUrl != null
        ) "CONTEXT_SUMMARIZER_SCREENPIPE_URL=${resolvedScreenpipeUrl}"
        ++ lib.optional (
          resolvedScreenpipeBin != null
        ) "CONTEXT_SUMMARIZER_SCREENPIPE_BIN=${resolvedScreenpipeBin}";
      }
      // lib.optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      };
    };

    systemd.user.timers.context-summarizer = {
      Unit.Description = "Trigger context-summarizer.service on a schedule";
      Timer = {
        OnCalendar = cfg.interval;

        Persistent = true;

        AccuracySec = "1min";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
