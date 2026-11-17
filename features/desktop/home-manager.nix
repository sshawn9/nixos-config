args@{ lib, self, ... }:
let
  context = self.lib.evaluationContext args;
in
{
  imports = [
    ./options.nix
  ]
  ++ self.lib.moduleFiles.list ./home-manager/common
  ++ lib.optionals context.inNixOS (self.lib.moduleFiles.list ./home-manager/embedded);
}
