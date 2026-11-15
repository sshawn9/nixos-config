{
  flake = {
    homeModules.fileSources = ./home-manager.nix;

    # TODO: Add nixosModules.fileSources with target paths relative to /.
    # Reuse layered source resolution and missing-source policies; expand
    # directories into per-file links. Use activation to create/update managed
    # links and remove obsolete managed links while preserving unrelated files.
    # Keep targets independent of environment.etc.
  };
}
