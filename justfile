set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

[private]
default:
    @just --unsorted --list

target := if path_exists("/etc/NIXOS") == "true" { "nixos" } else if os() == "macos" { "darwin" } else { "home" }
nh-domain := if target == "nixos" { "os" } else if target == "darwin" { "darwin" } else if target == "home" { "home" } else { error("target must be one of: nixos, darwin, home") }
hostname := `hostname -s`
default-home-configuration := env_var("USER") + "@" + hostname

# Format all Nix files
[group("repo")]
fmt:
    nix fmt .

# Update flake.lock
[group("repo")]
update:
    nix flake update

# Check all flake outputs
[group("repo")]
check:
    nix flake check --all-systems

# Lint Nix files
[group("repo")]
lint:
    statix check .
    deadnix --fail .

# Inspect flake.lock interactively
[group("repo")]
lock-view:
    nix-melt flake.lock

# Original: nix build {{ FLAGS }} --print-build-logs .#nixosConfigurations.{{ HOST }}.config.system.build.toplevel
# Build a NixOS host (default: current hostname)
[group("nixos")]
nixos-build HOST=hostname *FLAGS:
    nh os build --hostname {{ quote(HOST) }} --out-link result . {{ FLAGS }}

# Original: nixos-rebuild dry-build {{ FLAGS }} --flake .#{{ HOST }}
# Dry-run a NixOS host build
[group("nixos")]
nixos-build-dry-run HOST=hostname *FLAGS:
    nixos-rebuild dry-build {{ FLAGS }} --flake {{ quote(".#" + HOST) }}

# Original: nixos-rebuild test {{ FLAGS }} --sudo --flake .#{{ HOST }}
# Test-activate a NixOS host without making it permanent
[group("nixos")]
nixos-test HOST=hostname *FLAGS:
    nh os test --hostname {{ quote(HOST) }} . {{ FLAGS }}

# Original: nixos-rebuild dry-activate {{ FLAGS }} --sudo --flake .#{{ HOST }}
# Dry-run test activation for a NixOS host
[group("nixos")]
nixos-test-dry-run HOST=hostname *FLAGS:
    nh os test --dry --hostname {{ quote(HOST) }} . {{ FLAGS }}

# Original: nixos-rebuild boot {{ FLAGS }} --sudo --flake .#{{ HOST }}
# Build a NixOS boot generation, but do not switch yet
[group("nixos")]
nixos-boot HOST=hostname *FLAGS:
    nh os boot --hostname {{ quote(HOST) }} . {{ FLAGS }}

# Original: nixos-rebuild dry-build {{ FLAGS }} --flake .#{{ HOST }}
# Dry-run a NixOS boot generation build
[group("nixos")]
nixos-boot-dry-run HOST=hostname *FLAGS:
    nh os boot --dry --hostname {{ quote(HOST) }} . {{ FLAGS }}

# Original: nixos-rebuild switch {{ FLAGS }} --sudo --flake .#{{ HOST }}
# Switch a NixOS host
[group("nixos")]
nixos-switch HOST=hostname *FLAGS:
    nh os switch --hostname {{ quote(HOST) }} . {{ FLAGS }}

# Original: nixos-rebuild dry-run {{ FLAGS }} --sudo --flake .#{{ HOST }}
# Dry-run a NixOS switch
[group("nixos")]
nixos-switch-dry-run HOST=hostname *FLAGS:
    nh os switch --dry --hostname {{ quote(HOST) }} . {{ FLAGS }}

# Original: nix build {{ FLAGS }} --print-build-logs .#darwinConfigurations.{{ HOST }}.system
# Build a nix-darwin host (default: current hostname)
[group("darwin")]
darwin-build HOST=hostname *FLAGS:
    nh darwin build --hostname {{ quote(HOST) }} --out-link result . {{ FLAGS }}

# Original: nix build {{ FLAGS }} --dry-run --print-build-logs .#darwinConfigurations.{{ HOST }}.system
# Dry-run a nix-darwin host build
[group("darwin")]
darwin-build-dry-run HOST=hostname *FLAGS:
    nix build {{ FLAGS }} --dry-run --print-build-logs {{ quote(".#darwinConfigurations." + HOST + ".system") }}

# Original: sudo darwin-rebuild switch {{ FLAGS }} --flake .#{{ HOST }}
# Switch a nix-darwin host
[group("darwin")]
darwin-switch HOST=hostname *FLAGS:
    nh darwin switch --hostname {{ quote(HOST) }} . {{ FLAGS }}

# Original: darwin-rebuild check {{ FLAGS }} --flake .#{{ HOST }}
# Dry-run a nix-darwin switch
[group("darwin")]
darwin-switch-dry-run HOST=hostname *FLAGS:
    nh darwin switch --dry --hostname {{ quote(HOST) }} . {{ FLAGS }}

# Original: nix build {{ FLAGS }} --print-build-logs .#homeConfigurations.{{ CONFIGURATION }}.activationPackage
# Build a standalone Home Manager configuration
[group("home")]
home-build CONFIGURATION=default-home-configuration *FLAGS:
    nh home build --configuration {{ quote(CONFIGURATION) }} --out-link result . {{ FLAGS }}

# Original: nix build {{ FLAGS }} --dry-run --print-build-logs .#homeConfigurations.{{ CONFIGURATION }}.activationPackage
# Dry-run a standalone Home Manager configuration build
[group("home")]
home-build-dry-run CONFIGURATION=default-home-configuration *FLAGS:
    nix build {{ FLAGS }} --dry-run --print-build-logs {{ quote(".#homeConfigurations." + CONFIGURATION + ".activationPackage") }}

# Original: home-manager switch {{ FLAGS }} --flake .#{{ CONFIGURATION }}
# Switch a standalone Home Manager configuration
[group("home")]
home-switch CONFIGURATION=default-home-configuration *FLAGS:
    nh home switch --configuration {{ quote(CONFIGURATION) }} . {{ FLAGS }}

# Original: home-manager build {{ FLAGS }} --flake .#{{ CONFIGURATION }}
# Dry-run a standalone Home Manager switch
[group("home")]
home-switch-dry-run CONFIGURATION=default-home-configuration *FLAGS:
    nh home switch --dry --configuration {{ quote(CONFIGURATION) }} . {{ FLAGS }}

# Original: just nixos-build / darwin-build / home-build based on nh-domain
# Build the auto-detected local configuration
[group("configuration")]
build NAME="" *FLAGS:
    just {{ if nh-domain == "os" { "nixos-build" } else if nh-domain == "darwin" { "darwin-build" } else { "home-build" } }} {{ if NAME == "" { "" } else { quote(NAME) } }} {{ FLAGS }}

# Original: just nixos-build-dry-run / darwin-build-dry-run / home-build-dry-run based on nh-domain
# Dry-run build the auto-detected local configuration
[group("configuration")]
build-dry-run NAME="" *FLAGS:
    just {{ if nh-domain == "os" { "nixos-build-dry-run" } else if nh-domain == "darwin" { "darwin-build-dry-run" } else { "home-build-dry-run" } }} {{ if NAME == "" { "" } else { quote(NAME) } }} {{ FLAGS }}

# Original: just nixos-test when nh-domain is os
# Test-activate the local NixOS configuration
[group("configuration")]
test NAME="" *FLAGS:
    {{ if nh-domain == "os" { "just nixos-test" } else { "printf '%s\\n' 'test is only supported for NixOS' >&2; false" } }} {{ if NAME == "" { "" } else { quote(NAME) } }} {{ FLAGS }}

# Original: just nixos-test-dry-run when nh-domain is os
# Dry-run test activation for the local NixOS configuration
[group("configuration")]
test-dry-run NAME="" *FLAGS:
    {{ if nh-domain == "os" { "just nixos-test-dry-run" } else { "printf '%s\\n' 'test dry-run is only supported for NixOS' >&2; false" } }} {{ if NAME == "" { "" } else { quote(NAME) } }} {{ FLAGS }}

# Original: just nixos-boot when nh-domain is os
# Build a boot generation for the local NixOS configuration
[group("configuration")]
boot NAME="" *FLAGS:
    {{ if nh-domain == "os" { "just nixos-boot" } else { "printf '%s\\n' 'boot is only supported for NixOS' >&2; false" } }} {{ if NAME == "" { "" } else { quote(NAME) } }} {{ FLAGS }}

# Original: just nixos-boot-dry-run when nh-domain is os
# Dry-run boot generation build for the local NixOS configuration
[group("configuration")]
boot-dry-run NAME="" *FLAGS:
    {{ if nh-domain == "os" { "just nixos-boot-dry-run" } else { "printf '%s\\n' 'boot dry-run is only supported for NixOS' >&2; false" } }} {{ if NAME == "" { "" } else { quote(NAME) } }} {{ FLAGS }}

# Original: just nixos-switch / darwin-switch / home-switch based on nh-domain
# Switch to the auto-detected local configuration
[group("configuration")]
switch NAME="" *FLAGS:
    just {{ if nh-domain == "os" { "nixos-switch" } else if nh-domain == "darwin" { "darwin-switch" } else { "home-switch" } }} {{ if NAME == "" { "" } else { quote(NAME) } }} {{ FLAGS }}

# Original: just nixos-switch-dry-run / darwin-switch-dry-run / home-switch-dry-run based on nh-domain
# Dry-run switch to the auto-detected local configuration
[group("configuration")]
switch-dry-run NAME="" *FLAGS:
    just {{ if nh-domain == "os" { "nixos-switch-dry-run" } else if nh-domain == "darwin" { "darwin-switch-dry-run" } else { "home-switch-dry-run" } }} {{ if NAME == "" { "" } else { quote(NAME) } }} {{ FLAGS }}

# Print roots that keep Nix store paths reachable
[group("maintenance")]
gc-print-roots:
    nix-store --gc --print-roots

# Collect unreachable store paths without deleting profile generations
[group("maintenance")]
gc-store *FLAGS:
    sudo nix-collect-garbage {{ FLAGS }}

# Delete profile generations older than DAYS days, then collect garbage
[group("maintenance")]
gc-older DAYS="180":
    sudo nix-collect-garbage --delete-older-than "{{ DAYS }}d"
    just refresh-boot-entries

# List NixOS system generations
[group("maintenance")]
list-generations:
    nixos-rebuild list-generations

# List non-current system generations whose NixOS label contains "dirty"
[group("maintenance")]
dirty-generations:
    nixos-rebuild list-generations --json | jq -r '.[] | select((.nixosVersion // "" | contains("dirty")) and (.current | not)) | "\(.generation)\t\(.date)\t\(.nixosVersion)"'

# Delete non-current dirty system generations from the default system profile
[group("maintenance")]
delete-dirty-generations:
    nixos-rebuild list-generations --json | jq -r '.[] | select((.nixosVersion // "" | contains("dirty")) and (.current | not)) | .generation' | xargs -r sudo nix-env -p /nix/var/nix/profiles/system --delete-generations
    just refresh-boot-entries

# Dry-run deletion of non-current dirty system generations
[group("maintenance")]
delete-dirty-generations-dry-run:
    nixos-rebuild list-generations --json | jq -r '.[] | select((.nixosVersion // "" | contains("dirty")) and (.current | not)) | .generation' | xargs -r sudo nix-env -p /nix/var/nix/profiles/system --delete-generations --dry-run

# List systemd-boot NixOS entries as generation rows
[group("maintenance")]
list-boot-entries:
    #!/usr/bin/env bash
    set -euo pipefail

    current_generation="$(nixos-rebuild list-generations --json | jq -r 'map(select(.current))[0].generation // ""')"

    sudo bash -eu -o pipefail -s -- "$current_generation" <<'BASH'
    current_generation="$1"

    {
        printf "%s\t%s\t%s\t%s\n" "Generation" "Current" "Entry" "Label"
        {
            shopt -s nullglob
            for entry in /boot/loader/entries/*.conf; do
                file="${entry##*/}"
                generation="$(awk '$1 == "version" { for (i = 1; i <= NF; i++) if ($i == "Generation") { print $(i + 1); exit } }' "$entry")"
                if [[ -z "$generation" && "$file" =~ generation-([0-9]+) ]]; then
                    generation="${BASH_REMATCH[1]}"
                fi
                [[ -n "$generation" ]] || continue

                label="$(awk '$1 == "version" { sub(/^version[[:space:]]+/, ""); print; exit }' "$entry")"
                if [[ -z "$label" ]]; then
                    label="$(awk '$1 == "title" { sub(/^title[[:space:]]+/, ""); print; exit }' "$entry")"
                fi
                label="${label#Generation $generation }"

                current=false
                if [[ "$generation" == "$current_generation" ]]; then
                    current=true
                fi

                printf "%s\t%s\t%s\t%s\n" "$generation" "$current" "$file" "$label"
            done | sort -n
        }
    } | column -t -s $'\t'
    BASH

# Refresh NixOS boot entries from the current system profile
[group("maintenance")]
refresh-boot-entries:
    sudo /run/current-system/bin/switch-to-configuration boot

# Diff a built system closure against the running system
[group("debug")]
diff-current RESULT="result":
    nvd diff /run/current-system {{ quote(RESULT) }}

# Browse the running system closure
[group("debug")]
tree-current:
    nix-tree /run/current-system

# Build a NixOS system and keep the result under .build-links
[group("debug")]
keep-nixos-build NAME="" HOST=hostname *FLAGS:
    #!/usr/bin/env bash
    set -euo pipefail

    base_name={{ quote(NAME) }}
    target_host={{ quote(HOST) }}
    installable=".#nixosConfigurations.${target_host}.config.system.build.toplevel"

    if [[ -z "$base_name" ]]; then
        base_name="$(date +%m%d-%H%M%S)"
    fi

    drv="$(nix eval --raw "${installable}.drvPath")"
    drv_name="${drv##*/}"
    drv_name="${drv_name%.drv}"
    drv_name="${drv_name//[^A-Za-z0-9._-]/_}"
    base_name="${base_name//[^A-Za-z0-9._-]/_}"
    link_name="$base_name-$drv_name"

    mkdir -p .build-links
    nix build {{ FLAGS }} \
      --print-build-logs \
      --out-link ".build-links/$link_name" \
      "$installable"

# Build a /nix/store/*.drv path and keep the outputs under .build-links
[group("debug")]
keep-derivation-build DRV NAME="" *FLAGS:
    #!/usr/bin/env bash
    set -euo pipefail

    drv={{ quote(DRV) }}
    base_name={{ quote(NAME) }}

    if [[ -z "$base_name" ]]; then
        base_name="$(date +%m%d-%H%M%S)"
    fi

    if [[ ! "$drv" =~ ^/nix/store/[A-Za-z0-9]+-.+\.drv$ ]]; then
        echo "Error: DRV must be a /nix/store/*.drv path"
        exit 2
    fi

    drv_name="${drv##*/}"
    drv_name="${drv_name%.drv}"
    drv_name="${drv_name//[^A-Za-z0-9._-]/_}"
    base_name="${base_name//[^A-Za-z0-9._-]/_}"
    link_name="$base_name-$drv_name"

    mkdir -p .build-links
    nix build {{ FLAGS }} \
      --print-build-logs \
      --out-link ".build-links/$link_name" \
      "$drv^*"
