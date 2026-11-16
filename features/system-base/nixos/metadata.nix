{
  config,
  lib,
  self,
  ...
}:
{
  config = lib.mkIf config.features.system-base.enable {
    system.configurationRevision = lib.mkDefault (self.rev or self.dirtyRev or null);
  };
}
