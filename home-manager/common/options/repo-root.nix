{
  config,
  lib,
  self,
  ...
}:

{
  options.my.paths.store.repoRoot = lib.mkOption {
    type = lib.types.path;
    default = self.outPath;
    description = ''
      Root path of this flake source as seen by Nix evaluation.

      In a flake build this points at the source copy in /nix/store, which is
      suitable for pure evaluation, directory enumeration, and derivation
      inputs.
    '';
  };

  options.my.paths.local.repoRoot = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/ghq/github.com/sshawn9/nixos-config";
    description = ''
      Mutable local checkout root for this repository.

      This is intentionally a string so callers such as mkOutOfStoreSymlink
      receive the local checkout path instead of a flake path copied into
      /nix/store.
    '';
  };
}
