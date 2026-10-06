{
  config,
  inputs,
  pkgs,
  ...
}:
let
  username = config.my.shared.username;
  user = config.users.users.${username};
  dataDir = "${user.home}/Foldergram";
  stateDir = "/var/lib/foldergram";
  foldergram = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.foldergram;
in
{
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 ${username} ${user.group} -"
  ];

  systemd.services.foldergram = {
    description = "Foldergram photo and video gallery";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = {
      SERVER_PORT = "4141";
      DATA_ROOT = stateDir;
      GALLERY_ROOT = dataDir;
    };

    serviceConfig = {
      User = username;
      Group = user.group;
      StateDirectory = "foldergram";
      StateDirectoryMode = "0700";
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "tmpfs";
      # Keep normal user permissions for the originals, while only exposing this
      # directory inside the service's otherwise hidden home filesystem.
      BindReadOnlyPaths = [ dataDir ];
      ExecStart = "${foldergram}/bin/foldergram";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
