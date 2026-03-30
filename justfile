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

# Rebuild and switch, updating all flake inputs first.
[group("building")]
upgrade HOST=`hostname`:
    just update
    just rebuild {{ HOST }}

# Update all flake inputs (or a specific one).
[group("update")]
update *INPUT:
    nix flake update {{ INPUT }}

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
install HOST:
    sudo nixos-install --flake .#{{ HOST }}
