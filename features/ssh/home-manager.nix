{
  lib,
  config,
  ...
}:
let
  inherit (config.lib.fileSources.local) link;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.ssh.enable {
    home.file = lib.mkIf config.programs.ssh.enable {
      ".ssh/config" = link ".ssh/config";

      ".ssh/config.d" = link {
        source = ".ssh/config.d";
        onMissing = "ignore";
      };

      ".ssh/id_ed25519.pub" = link ".ssh/id_ed25519.pub";
    };

    programs.ssh = {
      enable = lib.mkDefault true;
      enableDefaultConfig = lib.mkDefault false;
    };
  };
}
