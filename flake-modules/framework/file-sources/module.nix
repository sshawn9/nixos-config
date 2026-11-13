{
  _class,
  config,
  lib,
  options,
  ...
}:
{
  imports = [
    ./options.nix
  ]
  ++ lib.optional (_class == "nixos") ./nixos.nix
  ++ lib.optional (_class == "homeManager") ./home-manager.nix;

  # The same module also works in systems without Home Manager.
  config = lib.optionalAttrs (options ? home-manager.sharedModules) {
    home-manager.sharedModules = [
      ./module.nix
      { fileSources = lib.mkDefault config.fileSources; }
    ];
  };
}
