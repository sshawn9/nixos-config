{ lib, self, ... }:
{
  options.features.installer = {
    enable = lib.mkEnableOption "the graphical system installer";

    source = lib.mkOption {
      type = lib.types.path;
      default = lib.cleanSource self.outPath;
      defaultText = lib.literalExpression "lib.cleanSource self.outPath";
      description = "Repository snapshot copied to /etc/nixos/config.";
    };

    target = lib.mkOption {
      type = lib.types.path;
      description = "Directory in this repository containing the target's nixos.nix and home-manager.nix.";
    };

    offline.enable = lib.mkEnableOption "installation using only the contents of the medium";
  };
}
