{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.mousehop.homeManagerModules.default ];

  config = lib.mkIf config.features.programs.enable {
    programs.mousehop.enable = lib.mkDefault false;

    nix.settings = lib.mkIf config.programs.mousehop.enable {
      extra-substituters = [ "https://mousehop.cachix.org" ];
      extra-trusted-public-keys = [
        "mousehop.cachix.org-1:5wbRclpnaMFh5hRLx4BR+UMSkOfCiR2kfr6WLItDpPU="
      ];
    };
  };
}
