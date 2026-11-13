{ lib }:
optionPrefix:
{ module, location }:
let
  structural = [
    "_class"
    "_file"
    "key"
    "disabledModules"
    "imports"
    "require"
    "freeformType"
  ];
  apply =
    args:
    let
      value = module args;
      explicit = value ? config || value ? options;
      body = if explicit then value.config or { } else removeAttrs value structural;
      header =
        if explicit then
          value
        else
          removeAttrs (builtins.intersectAttrs (lib.genAttrs structural (_: null)) value) [ "require" ]
          // {
            imports = (value.require or [ ]) ++ (value.imports or [ ]);
          };
    in
    location
    // header
    // {
      config = lib.mkIf (lib.getAttrFromPath (optionPrefix ++ [ "enable" ]) args.config) body;
    };
in
lib.setFunctionArgs apply (lib.functionArgs module // { config = false; })
