{ self, ... }:
{
  imports = self.lib.moduleFiles.list ./home-manager;
}
