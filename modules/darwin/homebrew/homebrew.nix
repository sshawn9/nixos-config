{ lib, ... }:

{
  homebrew = {
    enable = lib.mkDefault true;

    onActivation = {
      extraFlags = [
        "install"
        "--no-upgrade"
        "--zap"
        "--force-cleanup"
      ];
    };

    global = {
      autoUpdate = lib.mkDefault false;
      brewfile = lib.mkDefault true;
    };

    casks = [
      "microsoft-edge"
      "macs-fan-control"
      "wechat"
      "moonlight"
      "antigravity"
      "github"
      "clion"
      "ghostty"
      "iina"
      "orbstack"
      "codex"
      "codex-app"
      "gswitch"
    ];
  };
}
