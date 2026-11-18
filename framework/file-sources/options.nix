{ inputs, lib, ... }:
{
  options.fileSources = {
    storeRoot = lib.mkOption {
      type = lib.types.path;
      default = inputs.self.outPath;
      description = ''
        Source root in the evaluation snapshot. Used to find and enumerate
        files for both store and local sources. Defaults to the project's
        flake repository root. Layer directories and ordinary
        source paths are relative to this root.
      '';
    };

    localRoot = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Matching repository root in a mutable checkout. Set this to an
        absolute string path to link local sources to that checkout.
        Linking local sources while this is null falls back to the snapshot
        in storeRoot and emits an evaluation warning.
      '';
    };

    baseDir = lib.mkOption {
      type = lib.types.str;
      default = "file-sources/base";
      description = "Base layer directory, relative to the source root.";
    };

    overrideDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Override layer directories, relative to the source root and ordered
        from low to high priority. Later layers win for the same file path.
      '';
    };
  };
}
