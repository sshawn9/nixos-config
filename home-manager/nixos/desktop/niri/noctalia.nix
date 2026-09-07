{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.programs.noctalia;
  configCheck = pkgs.runCommandLocal "noctalia-config-check" { GSETTINGS_BACKEND = "memory"; } ''
    export NOCTALIA_DATA_HOME="$TMPDIR/noctalia-data"
    export NOCTALIA_STATE_HOME="$TMPDIR/noctalia-state"
    ${lib.getExe cfg.package} config validate ${config.my.paths.store.xdgConfigLayeredSource "noctalia"}
    touch "$out"
  '';
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  config = lib.mkIf config.my.shared.desktops.niri.enable {
    programs.noctalia.enable = lib.mkDefault true;

    xdg.configFile."noctalia" = config.my.paths.local.xdgConfigLayeredTree "noctalia";

    # Validate the configuration; plugin downloads remain managed by Noctalia.
    home.checks = lib.optional (cfg.checkConfig && cfg.package != null) configCheck;

    home.packages = [
      pkgs.unstable.udiskie
      pkgs.unstable.ddcutil # DDC/CI brightness control for external monitors.
    ];
  };
}
