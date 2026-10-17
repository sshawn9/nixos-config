{ lib, pkgs, ... }:
let
  packageEntryType = lib.types.coercedTo lib.types.bool (enable: { inherit enable; }) (
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
  options.my.packages = lib.mkOption {
    type = lib.types.attrsOf packageEntryType;
    default = { };
    description = ''
      Packages to install, keyed by logical name. A boolean enables or
      disables an entry; an attribute set configures its enable and package
      options. Declared entries are disabled by default. Package defaults
      resolve by name from pkgs.unstable when available, otherwise pkgs.
      Use an explicit package for aliases or nested package attributes.
    '';
    example = lib.literalExpression ''
      {
        curl = true;
        wget = false;
        python = {
          enable = true;
          package = pkgs.python3;
        };
      }
    '';
  };
}
