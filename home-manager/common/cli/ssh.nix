{ lib, config, ... }:
{
  home.file.".ssh/config" = lib.mkIf config.programs.ssh.enable {
    source = config.my.paths.local.dotfilesLayeredSource ".ssh/config";
  };

  home.file.".ssh/config.d" = lib.mkIf config.programs.ssh.enable (
    config.my.paths.local.dotfilesLayeredTree ".ssh/config.d"
  );

  home.file.".ssh/id_ed25519.pub" = lib.mkIf config.programs.ssh.enable {
    source = config.my.paths.local.dotfilesLayeredSource ".ssh/id_ed25519.pub";
  };

  programs = {
    ssh = {
      enable = lib.mkDefault true;
      enableDefaultConfig = lib.mkDefault false;
    };
  };
}
