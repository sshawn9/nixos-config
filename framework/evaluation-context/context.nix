{
  _class,
  specialArgs ? { },
  ...
}:
let
  isHomeManager = _class == "homeManager";
  parentClass = specialArgs.osClass or null;
  systemClass = if isHomeManager then parentClass else _class;
in
{
  inherit isHomeManager;
  isNixOS = _class == "nixos";
  isDarwin = _class == "darwin";
  isSystemManager = _class == "systemManager";
  isEmbeddedHome = isHomeManager && parentClass != null;
  isStandaloneHome = isHomeManager && parentClass == null;
  inNixOS = systemClass == "nixos";
  inDarwin = systemClass == "darwin";
  inSystemManager = systemClass == "systemManager";
}
