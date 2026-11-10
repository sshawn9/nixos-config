{ config, lib, ... }:

{
  home-manager.users.${config.my.shared.username} =
    { config, ... }:
    {
      sops.secrets.ssh-login-key = lib.mkIf config.my.shared.sops.enable {
        sopsFile = ../../../sops/secrets/ssh/star.json;
        format = "binary";
        # Keep the existing IdentityFile path; plaintext stays outside the store.
        path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
    };
}
