{
  config,
  lib,
  pkgs,
  ...
}:
{
  # General-purpose tools without a natural home in the other categories.
  config = lib.mkIf config.features.programs.enable {
    programs = {
      tealdeer = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.tealdeer;
        settings.updates.auto_update = true;
      };
      navi = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.navi;
      };
    };

    package.bc = lib.mkDefault true;
  };
}
