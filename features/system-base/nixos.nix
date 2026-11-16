{ self, ... }:
{
  imports = [ ./options.nix ] ++ self.lib.moduleFiles.list ./nixos;
}
