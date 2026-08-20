{
  self,
  inputs,
  lib,
  config,
  ...
}:

let
  sopsCheckEnvironment = config.sops.environment // {
    HOME = "/var/empty";
    PATH = lib.makeBinPath config.sops.age.plugins;
  };

  sopsCheckEnvironmentExports = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg (toString value)}") (
      lib.filterAttrs (_: value: toString value != "") sopsCheckEnvironment
    )
  );
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  config = lib.mkIf config.my.shared.sops.enable {
    sops = {
      defaultSopsFile = self.outPath + "/sops/secrets/secrets.yaml";

      age.sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
      ];

      # Individual secrets are declared by whichever module consumes them.
    };

    system.preSwitchChecks.sops-decryption = ''
      ${sopsCheckEnvironmentExports}
      export NIXOS_ACTION=dry-activate

      echo "Checking sops decryption for user secrets..."
      ${config.sops.package}/bin/sops-install-secrets \
        -ignore-passwd \
        ${lib.escapeShellArg (toString config.system.build.sops-nix-users-manifest)}

      echo "Checking sops decryption for regular secrets..."
      ${config.sops.package}/bin/sops-install-secrets \
        -ignore-passwd \
        ${lib.escapeShellArg (toString config.system.build.sops-nix-manifest)}
    '';
  };
}
