{
  config,
  lib,
  self,
  ...
}:
let
  inherit (config.common) primaryUser;
in
{
  sops.secrets.starAgeSecretKey =
    lib.mkIf (config.features.sops.enable && config.home-manager.users.star.features.sops.enable)
      {
        sopsFile = self.outPath + "/secrets/star/age-secret-key.enc.json";
        format = "binary";
        owner = primaryUser;
      };
}
