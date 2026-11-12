[private]
default:
    @just --list

HOST := `hostname`
SYSTEM := `nix eval --impure --raw --expr builtins.currentSystem`

# Run a flake check on the config.
[group("checks")]
check args="":
    nix flake check \
        --keep-going \
        --show-trace \
        {{ args }}

# Run the pre-commit hooks.
[group("checks")]
pre-commit:
    nix build ".#checks.{{ SYSTEM }}.pre-commit" --no-link
    @echo "Pre-commit hooks passed for {{ SYSTEM }}."

# See development environment templates.
show-templates:
    nix flake show self --json 2>/dev/null | jq '.templates | map_values(.description) | del(.default)'

# Rebuild and switch to the specified host (defaults to current hostname).
[group("building")]
rebuild *args: pre-commit
    nh os switch . {{ args }}

# Clean up NixOS generations.
[group("building")]
clean:
    nh clean all --keep-since 7d --keep 3

# Update all flake inputs (or a specific one).
[group("update")]
update *input:
    nix flake update {{ input }}

# Bump DeepSeek Harness to upstream master and print the pnpm deps hash it needs.
[group("update")]
dsh-bump:
    nix flake update deepseek-harness
    nix build .#dsh.pnpmDeps --no-link 2>&1 | grep -o 'got: *sha256-[^ ]*' || echo "pnpm deps hash unchanged"

# Rebuild and switch, updating all flake inputs first.
[group("update")]
upgrade *args:
    just update
    just rebuild {{ args }}

# Build a host without switching to it.
[group("building")]
build host=HOST *args:
    nh os build . --hostname {{ HOST }} {{ args }}

# Deploy a node with deploy-rs.
[group("building")]
deploy node="eta" *args: pre-commit
    nix run --inputs-from . deploy-rs -- --skip-checks .#{{ node }} {{ args }}

# Roll back a bad upgrade by restoring flake.lock and rebuilding.
[group("update")]
rollback *args:
    git restore flake.lock
    just rebuild {{ args }}

# Scaffold a new host with a minimal configuration.
[group("install")]
add-host name:
    #!/usr/bin/env bash

    set -euo pipefail

    dir="modules/nixosModules/hosts/{{ name }}"
    template="modules/nixosModules/hosts/_example"
    if [ -d "$dir" ]; then
        echo "Error: Host '{{ name }}' already exists at $dir!" >&2
        exit 1
    fi

    cp -r "$template" "$dir"

    # Capitalise the first letter for the module name.
    module="$(echo '{{ name }}' | sed 's/./\U&/')"
    sed -i "s/hostHOSTNAME/host$module/g; s/HOSTNAME/{{ name }}/g" "$dir"/*.nix

    # Generate hardware configuration for the current machine.
    sudo nixos-generate-config --show-hardware-config > "$dir/hardware-configuration.nix"
    echo "Created host '{{ name }}' at $dir/."
    echo "Edit $dir/configuration.nix to add modules, hardware configuration, etc."

# Format all Nix files.
[group("checks")]
fmt:
    nix fmt .

# Set up disks for a host using disko. DESTRUCTIVE: Destroys existing data!
[group("install")]
disko host=HOST:
    sudo nix run github:nix-community/disko/latest \
        --experimental-features 'nix-command flakes' -- \
        --mode destroy,format,mount \
        modules/nixosModules/hosts/{{ host }}/disko-config.nix

# Install NixOS for the specified host (run after disko).
[group("install")]
install host=HOST *args:
    sudo nixos-install --flake .#{{ host }} {{ args }}

# Build a custom ISO image.
[group("building")]
iso:
    rm -rf result
    nix build .#nixosConfigurations.iso.config.system.build.isoImage --impure
    ln -sf result/iso/*.iso latest.iso

# Write the latest ISO to a flash drive.
[group("building")]
iso-install drive:
    just iso
    sudo dd if=latest.iso of={{ drive }} bs=4M status=progress oflag=sync

# Enroll a FIDO2 token (e.g. YubiKey) for LUKS disk decryption.
[group("install")]
fido2-enroll device:
    sudo systemd-cryptenroll --fido2-device=auto {{ device }}

# Create and enroll Secure Boot keys for a Lanzaboote host (run once, post-install).
[group("install")]
secureboot-setup:
    #!/usr/bin/env bash

    set -euo pipefail

    if [ ! -d /var/lib/sbctl ]; then
        sudo sbctl create-keys
    else
        echo "Keys already exist at /var/lib/sbctl; skipping create-keys."
    fi

    echo "Enrolling into firmware. This needs Setup Mode; --microsoft keeps"
    echo "vendor-signed option ROMs (GPU, SSD) working."
    sudo sbctl enroll-keys --microsoft

    just secureboot-verify

# Check that the current boot chain is signed.
[group("install")]
secureboot-verify:
    sudo sbctl status
    sudo sbctl verify

# Generate a standalone age key for sops-nix (user/dev key).
[group("secrets")]
age-keygen:
    mkdir -p ~/.config/sops/age
    age-keygen -o ~/.config/sops/age/keys.txt
    @echo "Back up ~/.config/sops/age/keys.txt to a password manager!"

# Derive an age public key from this host's SSH host key.
[group("secrets")]
age-host-key:
    nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'

# Generate the topology diagram and move it to `docs/`.
[group("building")]
topology:
    mkdir -p docs/
    rm -f docs/topology.svg
    nix build .#topology.x86_64-linux.config.output
    cp result/main.svg docs/topology.svg

# Build the Glove80 firmware and flash it (run on epsilon; optional halves: lh rh).
[group("glove80")]
glove80 *halves:
    nix run .#glove80-flash -- {{ halves }}

# Trigger an arctic vault snapshot now.
[group("backup")]
vault:
    sudo systemctl start arctic-vault.service
    journalctl -u arctic-vault.service --no-pager -n 20

# Render the declarative router backup locally without uploading it.
[group("router")]
router-generate:
    #!/usr/bin/env bash
    set -uo pipefail
    sudo systemctl start router-config-generate.service; rc=$?
    journalctl -u router-config-generate.service --no-pager -n 20 || true
    exit $rc

# Push the declarative config to the live Icotera router (a restore/upload).
[group("router")]
router-restore:
    #!/usr/bin/env bash
    set -uo pipefail
    sudo systemctl start router-config-push.service; rc=$?
    journalctl -u router-config-push.service --no-pager -n 30 || true
    exit $rc

# Run an OpenTofu command for the Hetzner IaC.
[group("infra")]
infra *args:
    nix develop .#infra -c \
        sops exec-env ~/nix-secrets/infra/hetzner.yaml \
        'tofu -chdir=tofu {{ args }}'

# Unlock eta's disk over initrd SSH as soon as it reboots (start before or after the reboot).
[group("infra")]
eta-unlock:
    #!/usr/bin/env bash

    set -euo pipefail

    # Fetch first so pinentry prompts before eta goes down.
    passphrase="$(gopass show -o security/drives/eta)"
    opts=(-o ConnectTimeout=5 -o ConnectionAttempts=1 -o BatchMode=yes)

    echo "Waiting for eta's initrd SSH..."
    sent=0
    while :; do
        rc=0
        ssh "${opts[@]}" eta-initrd <<< "$passphrase" > /dev/null 2>&1 || rc=$?
        if [ "$rc" -ne 255 ]; then
            # The agent exits if no prompt is pending yet, so resend until initrd SSH goes away.
            [ "$sent" -eq 0 ] && echo "Connected, sending passphrase..."
            sent=$((sent + 1))
            if [ "$sent" -ge 30 ]; then
                echo "Initrd SSH still up after $sent attempts, check eta's console." >&2
                exit 1
            fi
        elif [ "$sent" -gt 0 ]; then
            break
        fi
        sleep 2
    done

    echo "Initrd SSH closed, waiting for eta to come up..."
    until ssh "${opts[@]}" -o ClearAllForwardings=yes eta true 2> /dev/null; do
        sleep 2
    done
    echo "eta is up."
