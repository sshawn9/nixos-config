# { inputs, pkgs, ... }:

{
  # imports = [ inputs.x-laptune.nixosModules.default ];

  # programs.x-laptune = {
  #   enable = true;
  #   package = inputs.x-laptune.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # };

  # services.x-laptune = {
  #   batteryControl.enable = true;
  #   memoryThermalControl.enable = true;
  # };
}
