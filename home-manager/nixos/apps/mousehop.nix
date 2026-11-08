{
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [ inputs.mousehop.homeManagerModules.default ];

  programs.mousehop = {
  };

  nix.settings = lib.mkIf config.programs.mousehop.enable {
    extra-substituters = [ "https://mousehop.cachix.org" ];
    extra-trusted-public-keys = [
      "mousehop.cachix.org-1:5wbRclpnaMFh5hRLx4BR+UMSkOfCiR2kfr6WLItDpPU="
    ];
  };
}
