args@{
  config,
  lib,
  self,
  ...
}:
let
  context = self.lib.evaluationContext args;
in
{
  config =
    lib.mkIf (context.inNixOS && config.features.sops.enable && args.osConfig.features.sops.enable)
      {
        xdg.configFile."sops/age/keys.txt".source =
          config.lib.file.mkOutOfStoreSymlink args.osConfig.sops.secrets.starAgeSecretKey.path;

        # Preserve the upstream activation command, but run it after the key link exists.
        home.activation.sops-nix = lib.hm.dag.entryAfter [ "linkGeneration" ] (lib.mkDefault "");
      };
}
