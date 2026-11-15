{ lib, pkgs, ... }:
let
  entryType = lib.types.coercedTo lib.types.bool (enable: { inherit enable; }) (
    lib.types.submodule (
      { name, ... }:
      {
        options = {
          enable = lib.mkEnableOption name;
          package = lib.mkPackageOption (pkgs.unstable or pkgs) name {
            pkgsText = "(pkgs.unstable or pkgs)";
          };
        };
      }
    )
  );
in
{
  options.package = lib.mkOption {
    type = lib.types.attrsOf entryType;
    default = { };
    description = ''
      Packages selected for this system or Home Manager user, keyed by logical
      name. A boolean sets enable; an attribute set configures enable and
      package. Entries default to disabled. Package defaults resolve by name
      from pkgs.unstable when available, otherwise pkgs.
    '';
    example = lib.literalExpression ''
      {
        curl = true;
        wget = false;
        python = {
          enable = true;
          package = pkgs.unstable.python3;
        };
      }
    '';
  };
}
