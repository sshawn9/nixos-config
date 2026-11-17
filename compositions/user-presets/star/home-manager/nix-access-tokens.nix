{
  config,
  lib,
  self,
  ...
}:
{
  config = lib.mkIf (config.features.sops.enable && config.nix.enable) {
    sops = {
      secrets.githubPAT = {
        sopsFile = self.outPath + "/secrets/star/github_pat.enc.yaml";
        key = "github_pat";
      };
      templates."nix-access-tokens.conf" = {
        content = ''
          access-tokens = github.com=${config.sops.placeholder.githubPAT}
        '';
        mode = "0400";
      };
    };

    nix.extraOptions = ''
      !include ${config.sops.templates."nix-access-tokens.conf".path}
    '';
  };
}
