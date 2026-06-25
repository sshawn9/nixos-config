{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.my.shared) username;
in
{
  # Rootless docker registers a *user* unit at /etc/systemd/user/docker.service,
  # which systemd-user auto-starts for every user that logs in — including the
  # greetd `greeter` system user (UID 987), which has no subuid range and so
  # always fails with "No subuid ranges found". Upstream sets
  # ConditionUser = "!root", which still matches greeter; tighten it to userName
  # via mkForce so systemd skips the unit cleanly for every other user
  # (ConditionUser leaves the unit inactive, not failed).
  systemd.user.services.docker.unitConfig.ConditionUser = lib.mkForce username;

  virtualisation = {
    containers.enable = lib.mkDefault true;

    docker = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.docker;
      rootless = {
        enable = lib.mkDefault true;
        setSocketVariable = lib.mkDefault false;
      };
    };

    podman = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.podman;
      defaultNetwork.settings.dns_enabled = lib.mkDefault true;
    };
  };

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = lib.mkDefault true;
  };

  users.users.${username} = {
    extraGroups = [ "docker" ];
    linger = true;
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      unstable.podman-compose

      unstable.docker-compose

      unstable.distrobox

      # fuse-overlayfs
    ];

    sessionVariables = {
      DBX_CONTAINER_MANAGER = "podman";
    };
  };
}
