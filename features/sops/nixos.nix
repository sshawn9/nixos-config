{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  environmentArguments = lib.escapeShellArgs (
    lib.mapAttrsToList (name: value: "${name}=${value}") (
      config.sops.environment
      // {
        HOME = "/var/empty";
        PATH = lib.makeBinPath config.sops.age.plugins;
        NIXOS_ACTION = "dry-activate";
      }
    )
  );
in
{
  imports = [
    ./options.nix
    inputs.sops-nix.nixosModules.sops
  ];

  config = lib.mkIf config.features.sops.enable {
    sops.age.sshKeyPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];

    sops.defaultSopsFile = lib.mkIf (config.features.sops.defaultSopsFile != null) (
      lib.mkDefault config.features.sops.defaultSopsFile
    );

    system.preSwitchChecks.sops-decryption =
      lib.mkIf (config.sops.secrets != { } || config.sops.templates != { })
        ''
          echo "Checking sops decryption for user secrets..."
          ${pkgs.coreutils}/bin/env -i ${environmentArguments} \
            ${config.sops.package}/bin/sops-install-secrets \
            -ignore-passwd \
            ${lib.escapeShellArg (toString config.system.build.sops-nix-users-manifest)}

          echo "Checking sops decryption for regular secrets..."
          ${pkgs.coreutils}/bin/env -i ${environmentArguments} \
            ${config.sops.package}/bin/sops-install-secrets \
            -ignore-passwd \
            ${lib.escapeShellArg (toString config.system.build.sops-nix-manifest)}
        '';
  };
}
