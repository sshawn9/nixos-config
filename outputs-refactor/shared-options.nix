{
  config,
  lib,
  options,
  ...
}:
let
  sourceUser = config.sharedOptionsUser;
  userOptions = lib.modules.mapAttrsOfSubmodule (
    _: { opt, ... }: opt.features or { }
  ) options.home-manager.users;
  sourceOptions = if sourceUser == null then { } else userOptions.${sourceUser};
in
{
  options.sharedOptionsUser = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
  };

  config = lib.optionalAttrs (options ? features) {
    features = lib.mapAttrsRecursiveCond (value: !lib.isOption value) (
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
    ) options.features;
  };
}
