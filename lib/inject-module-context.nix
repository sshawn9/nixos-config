# lib/_inject-module-context.nix
#
# Purpose
# -------
# Inject `moduleCtx` as a module argument across an evaluation, so any
# downstream module can write `{ moduleCtx, ... }:` and immediately receive
# a record of context-detection booleans (inNixOSProper, inEmbeddedHM, ...)
# without re-deriving them from `config` / `osConfig` / `pkgs` at every
# call site.
#
# Why this file exists (the case for centralisation)
# --------------------------------------------------
# The `myLib.in*` predicates exported by `lib/module-context.nix` need three
# irreducible inputs: `config`, `osConfig`, and `pkgs`. These only exist
# *inside a module evaluation*, so they cannot be baked into `myLib` at flake
# construction time. Without this injector, every consumer must restate the
# full plumbing:
#
#   { config, osConfig ? null, pkgs, lib, myLib, ... }@args:
#   lib.mkIf (myLib.inNixOSSystem args) { ... }
#
# That's a five-argument signature plus an `args@` capture plus the
# `osConfig ? null` discipline at every consumer. Forgetting the `? null`
# silently breaks evaluations that never pass `osConfig` (NixOS proper,
# nix-darwin, standalone HM), and the failure only surfaces on those rarely
# exercised paths.
#
# By placing this injector in a builder's modules list once, every consumer
# downstream collapses to:
#
#   { moduleCtx, lib, ... }:
#   lib.mkIf moduleCtx.inNixOSSystem { ... }
#
# Two named arguments instead of five, no `args@`, no `osConfig` discipline,
# no `myLib` reference leaking into shared-options-style modules that should
# not know the internal lib exists.
#
# How it works
# ------------
# `_module.args.X = Y` is the NixOS module system's mechanism for sharing a
# value as a function argument across all modules in the same evaluation.
# This file builds a single `moduleCtx` record by calling each `myLib.in*`
# predicate once against the evaluation's `config` / `osConfig` / `pkgs`,
# then publishes it under `_module.args.moduleCtx`. Modules in the same
# evaluation that pull `{ moduleCtx, ... }:` get this record back.
#
# How to wire it in a builder
# ---------------------------
# Add the file path to the builder's modules list, e.g. inside `mkHome`,
# `mkSystem`, or `mkDarwinSystem`:
#
#   modules = userModules ++ [
#     repoTree.lib._inject-module-context
#     # ... other shared modules
#   ];
#
# The `_` filename prefix tells haumea to skip auto-loading; explicit
# inclusion via `repoTree.lib._inject-module-context` is the only entry
# point.
#
# How to use it (consumer side)
# -----------------------------
# Pull `moduleCtx` from the module argument set and branch on its fields:
#
#   { moduleCtx, lib, ... }:
#   {
#     config = lib.mkMerge [
#       (lib.mkIf moduleCtx.inStandaloneHM { /* standalone-HM-only */ })
#       (lib.mkIf moduleCtx.inEmbeddedHM   { /* embedded-HM-only */ })
#       (lib.mkIf moduleCtx.inNixOSProper  { /* NixOS top-level only */ })
#       (lib.mkIf moduleCtx.inNixOSSystem  { /* anywhere under a NixOS system */ })
#       (lib.mkIf moduleCtx.inDarwinProper { /* nix-darwin top-level only */ })
#       (lib.mkIf moduleCtx.inDarwinSystem { /* anywhere under a darwin system */ })
#     ];
#   }
#
# Available fields mirror `lib/module-context.nix` exports:
# inHomeManager, inEmbeddedHM, inStandaloneHM, inNixOSProper, inDarwinProper,
# inNixOSSystem, inDarwinSystem.

{
  config,
  osConfig ? null,
  pkgs,
  myLib,
  ...
}:

let
  args = { inherit config osConfig pkgs; };
in
{
  _module.args.moduleCtx = {
    inHomeManager = myLib.inHomeManager args;
    inEmbeddedHM = myLib.inEmbeddedHM args;
    inStandaloneHM = myLib.inStandaloneHM args;
    inNixOSProper = myLib.inNixOSProper args;
    inDarwinProper = myLib.inDarwinProper args;
    inNixOSSystem = myLib.inNixOSSystem args;
    inDarwinSystem = myLib.inDarwinSystem args;
  };
}
