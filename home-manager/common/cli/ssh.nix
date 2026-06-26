{ lib, config, ... }:
{
  home.file.".ssh/config" = lib.mkIf config.programs.ssh.enable {
    source = config.my.paths.local.dotfilesLayeredSource ".ssh/config";
  };

  programs = {
    ssh = {
      enable = lib.mkDefault true;
      enableDefaultConfig = lib.mkDefault false;
    };
  };
}
