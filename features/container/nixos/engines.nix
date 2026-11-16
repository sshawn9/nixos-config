{
  config,
  lib,
  pkgs,
  ...
}:
let
  primaryUser = config.common.primaryUser;
in
{
  config = lib.mkIf config.features.container.enable {
    boot = {
      enableContainers = lib.mkDefault (!config.boot.isContainer);
      binfmt = {
        emulatedSystems = lib.optional (pkgs.stdenv.hostPlatform.system != "aarch64-linux") "aarch64-linux";
        preferStaticEmulators = lib.mkDefault true;
      };
    };

    virtualisation = {
      containers.enable = lib.mkDefault true;
      docker = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.docker;
        rootless = {
          enable = lib.mkDefault (primaryUser != null);
          package = lib.mkDefault pkgs.unstable.docker;
          setSocketVariable = lib.mkDefault false;
        };
      };
      podman = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.podman;
        defaultNetwork.settings.dns_enabled = lib.mkDefault true;
      };
    };

    # Keep the rootless daemon out of unrelated user sessions, including greeters.
    systemd.user.services.docker =
      lib.mkIf (config.virtualisation.docker.rootless.enable && primaryUser != null)
        {
          unitConfig.ConditionUser = lib.mkForce config.users.users.${primaryUser}.name;
        };

    users.users = lib.mkIf (primaryUser != null) {
      ${primaryUser} = {
        extraGroups = lib.optional config.virtualisation.docker.enable "docker";
        linger = lib.mkDefault true;
        autoSubUidGidRange = lib.mkDefault true;
      };
    };
  };
}
