{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.mousehop.homeManagerModules.default ];

  config = lib.mkIf config.features.programs.enable {
    programs = {
      discord = {
        enable = lib.mkDefault false;
        package = lib.mkDefault pkgs.unstable.discord;
      };
      mousehop.enable = lib.mkDefault false;
    };

    package = {
      google-chrome = lib.mkDefault false;
      microsoft-edge = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (lib.mkDefault false);
      telegram-desktop = lib.mkDefault false;
      obsidian = lib.mkDefault false;
    };

    nix.settings = lib.mkIf config.programs.mousehop.enable {
      extra-substituters = [ "https://mousehop.cachix.org" ];
      extra-trusted-public-keys = [
        "mousehop.cachix.org-1:5wbRclpnaMFh5hRLx4BR+UMSkOfCiR2kfr6WLItDpPU="
      ];
    };
  };
}
