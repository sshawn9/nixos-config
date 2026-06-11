{ lib, ... }:

{
  options.my.paths.dotfilesLayers = {
    baseDir = lib.mkOption {
      type = lib.types.str;
      default = "base";
      description = ''
        Base layer directory name under each dotfiles root.
      '';
    };

    overrideDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Override layer directory names under each dotfiles root.

        Override directories are ordered from low to high priority. For the same
        relative file path, later override layers win.
      '';
    };
  };
}
