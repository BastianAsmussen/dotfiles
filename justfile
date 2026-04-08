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
rebuild HOST=`hostname`:
    nh os switch --hostname {{ HOST }} .

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
upgrade HOST=`hostname`:
    just update
    just rebuild {{ HOST }}

# Format all Nix files.
[group("checks")]
fmt:
    nix fmt .

# Set up disks for a host using disko (DESTRUCTIVE - destroys existing data!).
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

# Generate the topology diagram and move it to `docs/`.
[group("building")]
topology:
    mkdir -p docs/
    rm -f docs/topology.svg
    nix build .#topology.x86_64-linux.config.output
    cp result/main.svg docs/topology.svg
