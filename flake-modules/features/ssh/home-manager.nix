{ lib, config, ... }:
let
  files = config.lib.fileSources.local;
in
{
  home.file = lib.mkIf config.programs.ssh.enable {
    ".ssh/config" = files.link {
      source = ".ssh/config";
      onMissing = "ignore";
    };

    ".ssh/config.d" = files.link {
      source = ".ssh/config.d";
      onMissing = "ignore";
    };

    ".ssh/id_ed25519.pub" = files.link {
      source = ".ssh/id_ed25519.pub";
      onMissing = "ignore";
    };
  };

  programs.ssh = {
    enable = lib.mkDefault true;
    enableDefaultConfig = lib.mkDefault false;
  };
}
