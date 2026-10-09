{
  config,
  lib,
  inputs,
  ...
}:

{
  imports = [ inputs.noctalia.nixosModules.default ];

  config = lib.mkIf config.my.shared.desktop.noctalia.enable {
    programs.noctalia = {
      enable = lib.mkDefault true;
      systemd.enable = lib.mkDefault true;
      recommendedServices.enable = lib.mkDefault true;
    };
  };
}
