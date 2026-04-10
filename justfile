[private]
default:
    @just --list

# Run a flake check on the config.
[group("checks")]
check ARGS="":
    nix flake check \
        --keep-going \
        --show-trace \
        {{ ARGS }}

# Rebuild and switch to the specified host (defaults to current hostname).
[group("building")]
rebuild *ARGS:
    nh os switch . {{ ARGS }}

# Clean up NixOS generations.
[group("building")]
clean:
    nh clean all --keep-since 7d --keep 3

# Update all flake inputs (or a specific one).
[group("update")]
update *INPUT:
    nix flake update {{ INPUT }}

# Rebuild and switch, updating all flake inputs first.
[group("update")]
upgrade *ARGS:
    just update
    just rebuild {{ ARGS }}

# Roll back a bad upgrade by restoring flake.lock and rebuilding.
[group("update")]
rollback *ARGS:
    git restore flake.lock
    just rebuild {{ ARGS }}

# Scaffold a new host with a minimal configuration.
[group("install")]
add-host NAME:
    #!/usr/bin/env bash

    set -euo pipefail

    dir="modules/nixosModules/hosts/{{ NAME }}"
    template="modules/nixosModules/hosts/_example"
    if [ -d "$dir" ]; then
        echo "Error: Host '{{ NAME }}' already exists at $dir!" >&2
        exit 1
    fi

    cp -r "$template" "$dir"

    # Capitalise the first letter for the module name.
    module="$(echo '{{ NAME }}' | sed 's/./\U&/')"
    sed -i "s/hostHOSTNAME/host$module/g; s/HOSTNAME/{{ NAME }}/g" "$dir"/*.nix

    # Generate hardware configuration for the current machine.
    sudo nixos-generate-config --show-hardware-config > "$dir/hardware-configuration.nix"
    echo "Created host '{{ NAME }}' at $dir/"
    echo "Edit $dir/configuration.nix to add modules, hardware configuration, etc."

# Format all Nix files.
[group("checks")]
fmt:
    nix fmt .

# Set up disks for a host using disko. DESTRUCTIVE: Destroys existing data!
[group("install")]
disko HOST:
    sudo nix run github:nix-community/disko/latest \
        --experimental-features 'nix-command flakes' -- \
        --mode destroy,format,mount \
        modules/nixosModules/hosts/{{ HOST }}/disko-config.nix

# Install NixOS for the specified host (run after disko).
[group("install")]
install HOST *ARGS:
    sudo nixos-install --flake .#{{ HOST }} {{ ARGS }}

# Build a custom ISO image.
[group("building")]
iso:
    rm -rf result
    nix build .#nixosConfigurations.iso.config.system.build.isoImage --impure
    ln -sf result/iso/*.iso latest.iso

# Write the latest ISO to a flash drive.
[group("building")]
iso-install DRIVE:
    just iso
    sudo dd if=latest.iso of={{ DRIVE }} bs=4M status=progress oflag=sync

# Enroll a FIDO2 token (e.g. YubiKey) for LUKS disk decryption.
[group("install")]
fido2-enroll DEVICE:
    sudo systemd-cryptenroll --fido2-device=auto {{ DEVICE }}

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
