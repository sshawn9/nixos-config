{
  config,
  inputs,
  lib,
  ...
}:
let
  # Every input's source, the inputs of inputs included. `or { }` covers inputs
  # declared with `flake = false`, which carry sources but no input graph.
  collectSources =
    input:
    [ input.outPath ] ++ lib.concatMap collectSources (builtins.attrValues (input.inputs or { }));
in
{
  # The installed flake supplies a yescrypt hash generated from the password
  # entered in Calamares.  Keep it as the sole password source: these three
  # options all outrank hashedPassword when users are immutable.
  users.users.${config.my.shared.username} = {
    initialPassword = lib.mkForce null;
    password = lib.mkForce null;
    hashedPasswordFile = lib.mkForce null;
  };

  # Keep the complete locked input graph available for offline re-evaluation.
  # The generated flake locks `path:./config` on the installed machine, which
  # only succeeds if every input's source is already in the store.
  # `self` is excluded: the configuration source reaches the medium on its own.
  system.extraDependencies = lib.unique (
    lib.concatMap collectSources (builtins.attrValues (removeAttrs inputs [ "self" ]))
  );
}
