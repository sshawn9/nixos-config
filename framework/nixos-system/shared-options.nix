{
  config,
  lib,
  options,
  ...
}:
let
  sourceUser = config.sharedOptionsUser;
  sharedOptions = lib.filterAttrs (
    name: _:
    lib.elem name [
      "features"
      "common"
      "fileSources"
    ]
  ) options;
  userOptions = lib.modules.mapAttrsOfSubmodule (_: { opt, ... }: opt) options.home-manager.users;
  sourceOptions = if sourceUser == null then { } else userOptions.${sourceUser};
in
{
  options.sharedOptionsUser = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
  };

  config = lib.mapAttrsRecursiveCond (value: !lib.isOption value) (
    path: _:
    let
      sourceOption = lib.attrByPath path {
        isDefined = false;
        definitions = [ ];
      } sourceOptions;
    in
    lib.mkIf (sourceOption.isDefined && sourceOption.value != null) (
      lib.modules.mkAliasDefinitions sourceOption
    )
  ) sharedOptions;
}
