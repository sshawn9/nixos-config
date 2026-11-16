{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.features.container.enable {
    package = {
      regctl = lib.mkDefault true;
      skopeo = lib.mkDefault true;
    };
  };
}
