{ lib, ... }:
{
  options.features.ssh.enable = lib.mkEnableOption "SSH client and server configuration" // {
    default = true;
  };
}
