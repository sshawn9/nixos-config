{
  # The medium is not a host, so it does not reach modules/common/nix, where
  # every machine in this flake turns these on. It needs them for itself: the
  # flow installs with `nixos-install --flake`, and the flake the installer
  # writes onto the target is locked and evaluated here, on the medium.
  #
  # Not optional and not tied to `offline.enable` either. `flake-registry`, set
  # there, is not even a recognised setting until `flakes` is on: nix.conf
  # validation rejects it and the medium fails to build.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
