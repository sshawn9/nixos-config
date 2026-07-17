---
name: refresh-flake-input-comments
description: Audit and update Nix flake input comments that document non-trivial upstream dependency trees and the local all/partial/none follow policy, while skipping raw flake=false sources and trivial nixpkgs pins or aliases. Use when flake inputs, flake.lock, follows overrides, package consumption, or binary-cache configuration changes, or when asked to verify or refresh the input comments in this repository.
---

# Refresh Flake Input Comments

Keep the `# Upstream inputs:` trees faithful to each locked upstream flake and
keep the separate `# Follow policy:` rationale faithful to this repository.

## Guardrails

- Treat the upstream graph and local follow policy as separate facts.
- Reconstruct upstream graphs from each input's exact locked revision. Never use
  this repository's already-collapsed lock graph as the upstream graph.
- Skip `flake = false` sources, trivial nixpkgs pins with no upstream inputs,
  and local aliases that only point to those nixpkgs pins. Do not generate or
  compare comment blocks for them.
- Change comments only. Do not change URLs, `follows`, `flake = false`, or lock
  files unless the user explicitly requests policy implementation.
- Do not invent a rationale. If the current policy conflicts with the rules
  below, call that out instead of disguising it as intentional.
- Preserve unrelated worktree changes and use read-only Git commands.

## Workflow

1. Select the target flake. Default to the repository-root `flake.nix`; accept a
   nested flake directory when the user names one.
2. Rebuild independent upstream trees:

   ```console
   python3 .agents/skills/refresh-flake-input-comments/scripts/inspect_upstream_inputs.py --flake .
   ```

   The script is read-only and uses `nix flake metadata --no-write-lock-file`.
   It emits only non-trivial flake inputs. Treat failures as unknown data: do
   not guess or delete the existing tree.
3. Inspect local overrides and existing comments:

   ```console
   rg -n 'Upstream inputs:|Follow policy:|\.follows|flake = false' flake.nix
   ```

4. Classify each root input from the target flake's own definitions:

   - `N/A`: a non-nixpkgs flake with no upstream inputs.
   - `all (alias)`: a root alias implemented entirely with `.follows`.
   - `all`: every direct upstream input is redirected to a root counterpart.
   - `partial`: only some direct inputs are redirected, or only nested inputs
     are redirected while the complete upstream graph is not.
   - `none`: no local follow override exists anywhere below that root input.

   Do not count an upstream flake's native shared edge as a local follow.
5. Re-evaluate the reason; never copy it blindly. Search actual consumers and
   cache configuration:

   ```console
   rg -n --glob '*.nix' 'inputs\.<input-name>\b' .
   rg -n 'substituters|trusted-public-keys|cache\.enable|cachix|garnix|attic' .
   ```

   Apply these repository rules against future root-input updates, not merely
   the revisions that happen to match today:

   - Preserve upstream dependency pins when a consumed package is expensive and
     an upstream binary cache is expected to supply that exact derivation.
   - Follow shared roots when a cache miss only rebuilds a cheap wrapper or other
     lightweight derivation.
   - Otherwise prefer follows to remove redundant inputs.
   - Follow evaluation-only and module-only dependencies when they should share
     the host package set.
   - A formatting/check-only transitive input may follow without invalidating a
     runtime package cache; verify that it does not enter the consumed derivation.
   - Unique dependencies with no root counterpart may remain upstream and can
     explain a `partial` policy.
   - Never justify follows by saying current output paths happen to match; the
     root nixpkgs pins are intentionally updateable.
6. Update the immediately preceding comment block with `apply_patch`:

   ```nix
   # Upstream inputs:
   # input-name
   # ├── direct-input
   # │   └── transitive-input
   # └── shared-input (shared with input-name/direct-input)
   #
   # Follow policy: partial — concise reason tied to consumption and cache cost.
   input-name = { };
   ```

   Keep trees structural and glanceable. Show upstream-native shared nodes as
   `(shared with <path>)`; do not annotate tree edges with this repository's
   follows. Keep policy reasons to one to three lines.
7. Re-run the inspector and compare every emitted root input with its comment.
   Do not require comments for skipped sources or nixpkgs pins. Then run:

   ```console
   nix fmt flake.nix
   nix flake metadata --no-write-lock-file
   nix flake check --all-systems --no-build --keep-going
   git diff -- flake.nix flake.lock
   ```

   For a nested flake, pass its directory to Nix and inspect its own lock file.
   Confirm `flake.lock` is unchanged when the request is comment-only.

## Report

State which upstream trees or policy classifications changed, which evidence
changed the rationale, and which checks passed. Mention unresolved metadata or
cache uncertainty explicitly.
