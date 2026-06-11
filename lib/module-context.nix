# lib/module-context.nix
#
# Background
# ----------
# Multiple frameworks reuse Nix's module system: NixOS, nix-darwin, and
# Home Manager. Each evaluates its own option tree independently, so a module
# file shared between them sometimes has to branch on which framework is
# actually evaluating it (for example to apply a NixOS-only systemd service
# when the same module is also imported into Home Manager).
#
# This file exposes a flat set of `in*` predicates that derive a boolean from
# a module's arguments, identifying the current evaluation context. Two
# refinement levels are provided for the NixOS / nix-darwin axis:
#
#   inNixOSProper  - strict: NixOS top-level module evaluator only
#   inNixOSSystem  - broad:  NixOS module OR an embedded HM child under one
#
#   inDarwinProper - strict: nix-darwin top-level module evaluator only
#   inDarwinSystem - broad:  nix-darwin module OR an embedded HM child
#
# Use `*Proper` to select code that runs at the system level (e.g. systemd
# services, environment.systemPackages, NixOS-only options); use `*System`
# when the branch should fire for any module participating in the construction
# of that system, including the embedded HM portion.
#
# Detection principle
# -------------------
# Two anchors are sufficient to distinguish the four immediate evaluators:
#
# 1. `osConfig` is *only* set in embedded Home Manager. The NixOS Home Manager
#    integration injects `extraSpecialArgs.osConfig = config;` so HM modules
#    can read host-system options. NixOS, nix-darwin and standalone HM
#    evaluations never have it.
#
# 2. `config.home` (with `username`, `homeDirectory`, `stateVersion`) is a
#    root option declared by Home Manager and absent from NixOS / nix-darwin
#    option trees, so `config ? home` reliably reports "am I inside HM at all".
#
#   | evaluator      | config ? home | osConfig != null |
#   |----------------|---------------|------------------|
#   | NixOS          | false         | false            |
#   | nix-darwin     | false         | false            |
#   | embedded HM    | true          | true             |
#   | standalone HM  | true          | false            |
#
# Linux vs Darwin is taken from `pkgs.stdenv.hostPlatform`, which is reliable
# in every supported framework.
#
# Caller contract
# ---------------
# Modules that consume these predicates MUST declare `osConfig ? null` (with
# the default) in their argument list. Without the default, evaluations that
# never pass `osConfig` (NixOS, nix-darwin, standalone HM) fail because the
# strict module argument check rejects unbound names.
#
# Usage
# -----
#
#   { config, osConfig ? null, pkgs, lib, myLib, ... }@args:
#   {
#     config = lib.mkMerge [
#       (lib.mkIf (myLib.inStandaloneHM args) { /* standalone-HM-only */ })
#       (lib.mkIf (myLib.inEmbeddedHM   args) { /* embedded-HM-only */ })
#       (lib.mkIf (myLib.inNixOSProper  args) { /* NixOS top-level only */ })
#       (lib.mkIf (myLib.inNixOSSystem  args) { /* anywhere under a NixOS system */ })
#       (lib.mkIf (myLib.inDarwinProper args) { /* nix-darwin top-level only */ })
#       (lib.mkIf (myLib.inDarwinSystem args) { /* anywhere under a darwin system */ })
#     ];
#   }
#
# Combining with pkgs.stdenv.hostPlatform
# ---------------------------------------
# These predicates cover framework + Linux/Darwin host-OS dispatch. For CPU
# architecture, exact system strings or any further refinement, combine them
# with `pkgs.stdenv.hostPlatform` directly. nixpkgs is the source of truth
# there; this helper does not duplicate.
#
# Examples:
#
#   # Any Aarch64 evaluation, regardless of framework:
#   lib.mkIf pkgs.stdenv.hostPlatform.isAarch64 { /* ... */ }
#
#   # Standalone HM specifically on Apple Silicon:
#   lib.mkIf
#     (myLib.inStandaloneHM args
#      && pkgs.stdenv.hostPlatform.isDarwin
#      && pkgs.stdenv.hostPlatform.isAarch64)
#     { /* ... */ }
#
#   # NixOS x86_64 system module only:
#   lib.mkIf (myLib.inNixOSProper args && pkgs.stdenv.hostPlatform.isx86_64) { /* ... */ }

_:
let
  inHomeManager = { config, ... }: config ? home;

  inEmbeddedHM =
    args@{
      osConfig ? null,
      ...
    }:
    inHomeManager args && osConfig != null;

  inStandaloneHM =
    args@{
      osConfig ? null,
      ...
    }:
    inHomeManager args && osConfig == null;

  inNixOSProper = args@{ pkgs, ... }: !(inHomeManager args) && pkgs.stdenv.hostPlatform.isLinux;

  inDarwinProper = args@{ pkgs, ... }: !(inHomeManager args) && pkgs.stdenv.hostPlatform.isDarwin;

  inNixOSSystem =
    args@{ pkgs, ... }: inNixOSProper args || (inEmbeddedHM args && pkgs.stdenv.hostPlatform.isLinux);

  inDarwinSystem =
    args@{ pkgs, ... }: inDarwinProper args || (inEmbeddedHM args && pkgs.stdenv.hostPlatform.isDarwin);
in
{
  inherit
    inHomeManager
    inEmbeddedHM
    inStandaloneHM
    inNixOSProper
    inDarwinProper
    inNixOSSystem
    inDarwinSystem
    ;
}
