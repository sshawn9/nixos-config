{ config, lib, ... }:
{
  config = lib.mkIf config.features.programs.enable {
    package = {
      shellcheck = lib.mkDefault true;
      actionlint = lib.mkDefault true;
      ruff = lib.mkDefault true;
      shfmt = lib.mkDefault true;
    };
  };
}
