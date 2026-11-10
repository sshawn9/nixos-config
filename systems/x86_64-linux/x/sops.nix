{ config, lib, ... }:

let
  inherit (config.my.shared) username;
  ageKeyPath = config.sops.secrets.user-age-key.path;
in
{
  config = lib.mkIf config.my.shared.sops.enable {
    # Bootstrap the user's age identity with the host's SSH key.
    sops.secrets.user-age-key = {
      sopsFile = ../../../sops/secrets/age/star.json;
      format = "binary";
      owner = username;
    };

    home-manager.users.${username} =
      { config, lib, ... }:
      {
        xdg.configFile."sops/age/keys.txt".source = config.lib.file.mkOutOfStoreSymlink ageKeyPath;

        home.activation.sops-nix = lib.hm.dag.entryAfter [ "linkGeneration" ] (lib.mkDefault "");
      };
  };
}
