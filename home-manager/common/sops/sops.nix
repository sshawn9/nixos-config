{
  self,
  inputs,
  config,
  ...
}:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    defaultSopsFile = self.outPath + "/sops/secrets/secrets.yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    secrets = {
      "gh_pat" = { };
    };
    templates."nix-access-tokens.conf" = {
      content = ''
        access-tokens = github.com=${config.sops.placeholder.gh_pat}
      '';
      mode = "0400";
    };
  };

  nix.extraOptions = ''
    !include ${config.sops.templates."nix-access-tokens.conf".path}
  '';
}
