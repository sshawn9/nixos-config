args@{ lib, self, ... }:
let
  context = self.lib.evaluationContext args;
in
{
  imports = [
    ./options.nix
  ]
  ++ lib.optionals context.inNixOS (self.lib.moduleFiles.list ./home-manager/embedded);
}
