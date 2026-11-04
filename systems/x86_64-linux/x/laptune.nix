{ inputs, pkgs, ... }:

{
  imports = [ inputs.x-laptune.nixosModules.default ];

  programs.x-laptune = {
    enable = true;
    package = inputs.x-laptune.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  services.x-laptune = {
    memoryThermalControl.enable = true;
  };
}
