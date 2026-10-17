# moduleContext
# Scope:   universal
# Returns: framework-context booleans for the current module evaluation
# Use:     myLib.moduleContext args in an args@{ ... }: module
# Notes:   reads only _class and specialArgs.osClass, so it can be used in
#          imports. *Proper selects the system evaluator; *System also includes
#          Home Manager embedded in that framework.
# Example:
#   args@{ lib, myLib, ... }:
#   let context = myLib.moduleContext args; in
#   { imports = lib.optionals context.inNixOSProper [ ./nixos.nix ]; }

{ _class, specialArgs, ... }:
let
  osClass = specialArgs.osClass or null;
in
rec {
  inHomeManager = _class == "homeManager";
  inEmbeddedHM = inHomeManager && osClass != null;
  inStandaloneHM = inHomeManager && osClass == null;

  inNixOSProper = _class == "nixos";
  inDarwinProper = _class == "darwin";

  inNixOSSystem = inNixOSProper || (inHomeManager && osClass == "nixos");
  inDarwinSystem = inDarwinProper || (inHomeManager && osClass == "darwin");
}
