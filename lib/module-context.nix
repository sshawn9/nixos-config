# Pure framework-context predicates. These read only _class and
# specialArgs.osClass, so they can be used while resolving imports.
rec {
  # inHomeManager
  # Scope:   universal
  # Returns: whether the current evaluation is Home Manager
  # Use:     select Home Manager modules
  # Notes:   includes both standalone and embedded Home Manager
  # Example: myLib.inHomeManager { _class = "homeManager"; } => true
  inHomeManager = { _class, ... }: _class == "homeManager";

  # inEmbeddedHM
  # Scope:   universal
  # Returns: whether Home Manager is embedded in a system evaluation
  # Use:     select configuration that needs a parent system
  # Notes:   Home Manager supplies the parent's class in specialArgs.osClass
  # Example: myLib.inEmbeddedHM { _class = "homeManager"; specialArgs.osClass = "nixos"; } => true
  inEmbeddedHM =
    args@{ specialArgs, ... }: inHomeManager args && (specialArgs.osClass or null) != null;

  # inStandaloneHM
  # Scope:   universal
  # Returns: whether Home Manager is evaluated without a parent system
  # Use:     select standalone Home Manager configuration
  # Notes:   an absent or null osClass denotes standalone Home Manager
  # Example: myLib.inStandaloneHM { _class = "homeManager"; specialArgs = { }; } => true
  inStandaloneHM =
    args@{ specialArgs, ... }: inHomeManager args && (specialArgs.osClass or null) == null;

  # inNixOSProper
  # Scope:   universal
  # Returns: whether the current evaluation is NixOS
  # Use:     select NixOS system modules
  # Notes:   excludes Home Manager embedded in NixOS
  # Example: myLib.inNixOSProper { _class = "nixos"; } => true
  inNixOSProper = { _class, ... }: _class == "nixos";

  # inDarwinProper
  # Scope:   universal
  # Returns: whether the current evaluation is nix-darwin
  # Use:     select nix-darwin system modules
  # Notes:   excludes Home Manager embedded in nix-darwin
  # Example: myLib.inDarwinProper { _class = "darwin"; } => true
  inDarwinProper = { _class, ... }: _class == "darwin";

  # inNixOSSystem
  # Scope:   universal
  # Returns: whether the evaluation belongs to a NixOS system
  # Use:     select configuration shared by NixOS and its Home Manager users
  # Notes:   checks framework membership, independently of the target platform
  # Example: myLib.inNixOSSystem { _class = "homeManager"; specialArgs.osClass = "nixos"; } => true
  inNixOSSystem =
    args@{ specialArgs, ... }:
    inNixOSProper args || (inHomeManager args && (specialArgs.osClass or null) == "nixos");

  # inDarwinSystem
  # Scope:   universal
  # Returns: whether the evaluation belongs to a nix-darwin system
  # Use:     select configuration shared by nix-darwin and its Home Manager users
  # Notes:   checks framework membership, independently of the target platform
  # Example: myLib.inDarwinSystem { _class = "homeManager"; specialArgs.osClass = "darwin"; } => true
  inDarwinSystem =
    args@{ specialArgs, ... }:
    inDarwinProper args || (inHomeManager args && (specialArgs.osClass or null) == "darwin");
}
