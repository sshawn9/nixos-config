{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  targetPath = toString config.features.installer.target;
  relativeTarget =
    if lib.hasPrefix "${self.outPath}/" targetPath then
      lib.removePrefix self.outPath targetPath
    else
      throw "features.installer.target must be inside this repository.";
  configuration = pkgs.replaceVars ./calamares/flake.nix.in {
    system = pkgs.stdenv.hostPlatform.system;
    target = relativeTarget;
  };
  installer = pkgs.callPackage ./calamares {
    inherit configuration;
    inherit (config.features.installer) source;
    offline = config.features.installer.offline.enable;
  };
in
{
  imports = [
    ./options.nix
    ./offline.nix
  ];

  config = lib.mkIf config.features.installer.enable {
    security.polkit.enablePkexecWrapper = true;
    programs.partition-manager.enable = true;

    environment.systemPackages = [
      installer
      (pkgs.makeAutostartItem {
        name = "calamares";
        package = installer;
      })
    ];

    # The locale page must offer the same complete locale set as the target.
    i18n.supportedLocales = [ "all" ];
    environment.variables.QT_QPA_PLATFORM = "$([[ $XDG_SESSION_TYPE = \"wayland\" ]] && echo \"wayland\")";
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
