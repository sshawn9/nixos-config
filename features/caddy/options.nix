{ lib, ... }:
{
  options.features.caddy = {
    enable = lib.mkEnableOption "Caddy system and user web servers";
  };
}
