{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./options.nix
    inputs.sops-nix.homeManagerModules.sops
  ];

  config = lib.mkIf config.features.sops.enable {
    sops = {
      defaultSopsFile = lib.mkIf (config.features.sops.defaultSopsFile != null) (
        lib.mkDefault config.features.sops.defaultSopsFile
      );
      age.keyFile = lib.mkDefault "${config.xdg.configHome}/sops/age/keys.txt";
    };
  };
}
