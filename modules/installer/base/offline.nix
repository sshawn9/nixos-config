{
  self,
  lib,
  config,
  ...
}:
let
  # Passed only here, only to prebuild a closure. The flake the installer writes
  # imports the hardware it discovered on the machine in front of it, so these
  # disks have no path into an installed system.
  prebuildHardware = {
    hardware.enableAllHardware = true;

    boot.loader.efi.canTouchEfiVariables = true;

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000001";
      fsType = "ext4";
    };
  };

  prebuildSystem = self.installedSystems.${config.my.installer.target} [
    prebuildHardware
    {
      my.shared = {
        hostname = "prebuild";
        username = "prebuild";
      };

      # This value is built only to put its closure on the medium; unlike the
      # real installation it has no Calamares-supplied password hash.
      users.allowNoPasswordLogin = true;
    }
  ];

  # Small, configuration-building inputs which are deliberately absent from a
  # system's runtime closure. Most generated outputs can be substituted from
  # the prebuild system below once always-allow-substitutes overrides their
  # preferLocalBuild/allowSubstitutes flags. The outputs which really do vary
  # with the hardware or identity still have to be made locally, and these are
  # the non-runtime tools, secondary outputs, hardware-selected firmware, and
  # top-level builder/check outputs that those cheap builds need.
  configurationBuildInputs = [
    prebuildSystem.config.environment.etc."systemd/generator-environment.json".source.inputDerivation
    prebuildSystem.pkgs.getconf
    prebuildSystem.pkgs.kmod.dev
    prebuildSystem.pkgs.libcap.dev
    prebuildSystem.pkgs.libxml2Python
    prebuildSystem.pkgs.libxslt.bin
    prebuildSystem.pkgs.lndir
    prebuildSystem.pkgs.microcode-amd
    prebuildSystem.pkgs.microcode-intel
    prebuildSystem.pkgs.texinfo
  ]
  ++ prebuildSystem.config.system.checks
  ++ prebuildSystem.config.boot.initrd.services.udev.packages;
in
{
  # Any store path needed by the installation must already be present on the
  # medium. Forcing the substituters empty makes an omission fail loudly during
  # testing instead of silently reaching the network.
  config = lib.mkIf config.my.installer.offline.enable {
    nix.settings = {
      substituters = lib.mkForce [ ];
      flake-registry = "";

      # NixOS' small configuration generators normally force local builds even
      # when their exact output is already in the prebuild target closure. Let
      # the target store copy those outputs from the medium; outputs containing
      # the installer-supplied hostname or username have different hashes and
      # therefore continue to be built on the target.
      always-allow-substitutes = true;
    };

    # With no substituter left, everything the installation evaluates or builds
    # has to be on the medium already. The official ISO module carries the live
    # system; the target's own closure is the part it does not know about, and
    # it is needed exactly because there is nowhere to fetch it from.
    isoImage.storeContents = [
      prebuildSystem.config.system.build.toplevel
    ]
    ++ configurationBuildInputs;
  };
}
