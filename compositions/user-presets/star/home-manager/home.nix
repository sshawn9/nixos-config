{ config, lib, ... }:
let
  inherit (config.common) primaryUser;
in
{
  common.primaryUser = lib.mkDefault "star";
  home.username = lib.mkDefault primaryUser;
  home.homeDirectory = lib.mkDefault "/home/${primaryUser}";
  home.stateVersion = lib.mkDefault "26.11";

  fileSources = {
    overrideDirs = [ "file-sources/star" ];
    localRoot = lib.mkDefault "${config.home.homeDirectory}/ghq/github.com/sshawn9/nixos-config";
  };

  xdg.dataFile."personal" = config.lib.fileSources.local.xdgData.link {
    source = "personal";
    onMissing = "ignore";
  };
}
