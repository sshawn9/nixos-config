{ config, lib, ... }:
{
  fileSources = {
    overrideDirs = [ "file-sources/star" ];
    localRoot = lib.mkDefault "${config.home.homeDirectory}/ghq/github.com/sshawn9/nixos-config";
  };
}
