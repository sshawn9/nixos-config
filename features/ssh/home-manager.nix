{
  lib,
  config,
  ...
}:
let
  inherit (config.lib.fileSources.local) link;
in
{
  home.file = lib.mkIf config.programs.ssh.enable {
    ".ssh/config" = link {
      source = ".ssh/config";
      onMissing = "ignore";
    };

    ".ssh/config.d" = link {
      source = ".ssh/config.d";
      onMissing = "ignore";
    };

    ".ssh/id_ed25519.pub" = link {
      source = ".ssh/id_ed25519.pub";
      onMissing = "ignore";
    };
  };

  programs.ssh = {
    enable = lib.mkDefault true;
    enableDefaultConfig = lib.mkDefault false;
  };
}
