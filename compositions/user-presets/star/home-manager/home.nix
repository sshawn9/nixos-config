{ config, lib, ... }:
let
  inherit (config.common) primaryUser;
in
{
  common.primaryUser = lib.mkDefault "star";
  home.username = lib.mkDefault primaryUser;
  home.homeDirectory = lib.mkDefault "/home/${primaryUser}";
  home.stateVersion = lib.mkDefault "25.11";
}
