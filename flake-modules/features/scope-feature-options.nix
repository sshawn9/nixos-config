{ lib }:
optionPrefix:
{ module, location }:
let
  arguments = lib.functionArgs module;
in
lib.setFunctionArgs (
  args:
  location
  // {
    options = lib.setAttrByPath optionPrefix (
      module (if arguments == { } then args else lib.intersectAttrs arguments args)
    );
  }
) (lib.filterAttrs (_: optional: !optional) arguments)
