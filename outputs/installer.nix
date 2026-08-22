{
  self,
  inputs,
  lib,
  myLib,
  repoTree,
  nixpkgsPolicy,
}:
let
  # Every entry is a platform directory holding real installers. The shared
  # module layer lives in modules/installer, so this tree needs no reserved name
  # and stays the same shape as systems/ and homes/.
  installersTree = repoTree.installers or { };

  installerConfigurationsFor =
    system: lib.mapAttrs (name: _: mkInstaller system name) (installersTree.${system} or { });

  mkInstaller =
    system: name:
    (inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          self
          inputs
          system
          name
          myLib
          repoTree
          ;
      };
      modules = [
        # The shared layer, reached through one entry the way a host reaches the
        # whole module tree through modules/default.nix.
        repoTree.modules.installer-collect
        {
          imports = myLib.loadRecursiveModulePathList (self.outPath + "/installers/${system}/${name}");
          nixpkgs.pkgs = nixpkgsPolicy.mkPkgs system;
        }
      ];
    });

  # The evaluated media themselves, published so that a medium's configuration
  # can be inspected directly. Nested by system to stay one to one with the
  # packages they produce, which also means two platforms may carry installers
  # of the same name without any disambiguation rule.
  installerConfigurations = lib.genAttrs (builtins.attrNames installersTree) installerConfigurationsFor;
in
{
  # Contributed rather than assigned: any other module may define packages of
  # its own, and flake-parts merges them. A name defined twice fails loudly
  # instead of one source silently overwriting the other.
  flakeModule = {
    # Every module contributes the platforms it needs; flake-parts merges them.
    # Without this an installer on a platform no host uses would silently never
    # be built, taking its platform assertion down with it.
    systems = builtins.attrNames installersTree;

    flake = { inherit installerConfigurations; };

    perSystem =
      { system, ... }:
      {
        # One directory under installers/<system>/ is one installer, named
        # after it. Each medium declares which build product it publishes.
        packages = lib.mapAttrs (_name: installer: installer.config.my.installer.image) (
          installerConfigurationsFor system
        );
      };
  };
}
