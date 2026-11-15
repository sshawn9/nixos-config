{ self, ... }:
{
  imports = self.lib.moduleFiles.list ./nixos;
}
