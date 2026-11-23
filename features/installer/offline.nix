{
  config,
  inputs,
  lib,
  options,
  pkgs,
  self,
  ...
}:
let
  collectSources =
    input:
    [ input.outPath ] ++ lib.concatMap collectSources (builtins.attrValues (input.inputs or { }));
  sources = lib.concatMap collectSources (builtins.attrValues (removeAttrs inputs [ "self" ]));

  prebuildMachine = import ./prebuild-machine.nix;
  mkTarget =
    efi:
    self.lib.mkNixosSystem {
      system = pkgs.stdenv.hostPlatform.system;
      modules = [
        (config.features.installer.target + "/nixos.nix")
        (prebuildMachine {
          inherit efi;
          homeModule = config.features.installer.target + "/home-manager.nix";
        })
      ];
    };
  targets = [ (mkTarget true) ] ++ lib.optional pkgs.stdenv.hostPlatform.isx86 (mkTarget false);
in
{
  config = lib.mkIf (config.features.installer.enable && config.features.installer.offline.enable) (
    # Ordinary hosts also load this module, but do not declare ISO options.
    if options ? isoImage.storeContents then
      {
        isoImage.storeContents = lib.unique (
          sources
          ++ lib.concatMap (
            target:
            let
              inherit (target) config pkgs;
            in
            [
              config.system.build.toplevel
              # Build-only inputs absent from the prebuilt runtime closure.
              config.environment.etc."systemd/generator-environment.json".source.inputDerivation
              pkgs.getconf
              pkgs.kmod.dev
              pkgs.libcap.dev
              pkgs.lndir
              # GRUB configuration and boot menu resources.
              pkgs.libxml2Python
              pkgs.libxslt.bin
              pkgs.texinfo
              # A different keyboard selection can rebuild the console keymap.
              pkgs.ckbcomp
              pkgs.xkeyboard_config
            ]
            ++ lib.optionals pkgs.stdenv.hostPlatform.isx86 [
              pkgs.microcode-amd
              pkgs.microcode-intel
            ]
            # A selected greetd autologin session changes its TOML at install time.
            ++ ((pkgs.formats.toml { }).generate "installer-toml-build-inputs" { }).nativeBuildInputs
            ++ config.system.checks
            ++ config.boot.initrd.services.udev.packages
          ) targets
        );
      }
    else
      {
        assertions = [
          {
            assertion = false;
            message = "features.installer.offline requires a NixOS ISO configuration.";
          }
        ];
      }
  );
}
