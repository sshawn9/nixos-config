{ lib, ... }:

{
  homebrew = {
    enable = lib.mkDefault true;

    onActivation = {
      cleanup = lib.mkDefault "zap";
      autoUpdate = lib.mkDefault false;
      upgrade = lib.mkDefault false;
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
    ];
  };
}
