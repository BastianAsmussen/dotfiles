# dotfiles

This is a repository for my NixOS configuration.

## Topology

![Network Topology](docs/topology.svg)

## Table of Contents

- [Installation Guide](#installation-guide)
  - [LUKS & FIDO2](#luks--fido2)
  - [Age Key Generation (sops-nix)](#age-key-generation-sops-nix)
- [Maintenance Guide](#maintenance-guide)
- [To-Do Tracking](#to-do-tracking)
- [Development Templates](#development-templates)

## Installation Guide

### Boot Medium

You can boot from the custom ISO which comes with Git, my custom Neovim build,
and flakes pre-enabled.

Download the latest pre-built ISO from the
[Releases](https://github.com/BastianAsmussen/dotfiles/releases/latest) page,
or build it locally:

```sh
just iso
```

Then write it to a flash drive:

```sh
just iso-install /dev/sdX
```

> [!NOTE]
> If you don't have the custom ISO, a standard NixOS installer works too. You
> will just need to enter a Nix shell with Git first:
>
> ```sh
> nix-shell -p git
> ```

### Steps

1. Clone the Git repository.

   ```sh
   git clone https://github.com/BastianAsmussen/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. Enter the provided Nix development shell.

   ```sh
   nix develop
   ```

> [!NOTE]
> On a standard NixOS installer without flakes enabled, use the compatibility
> shell instead:
>
> ```sh
> nix-shell --experimental-features 'nix-command flakes'
> ```

1. Choose a host.
   1. View available host options.

      ```sh
      HOSTNAME=$(ls modules/nixosModules/hosts | fzf)
      ```

   2. Set manually, e.g. `lambda`.

      ```sh
      HOSTNAME=lambda
      ```

2. Set up the disk configuration.

   ```sh
   just disko $HOSTNAME
   ```

3. Finally, install NixOS with the given configuration.

   ```sh
   just install $HOSTNAME
   ```

### Possible Errors and Workarounds

- `error: creating pipe: Too many open files`

  Simply increase the open file limit, i.e. setting it to `2048`.

  ```sh
  ulimit -n 2048
  ```

- `warning: download buffer is full; consider increasing the 'download-buffer-size' setting`

  It's worth to consider increasing the download buffer during installation.
  Like the warning suggests, this can be accomplished by increasing the
  `download-buffer-size` setting; pass `--option download-buffer-size n` where
  `n` is the buffer size to the `just install` command from step 3.

> [!IMPORTANT]
> Remember to change the password of the user!

### LUKS & FIDO2

Hosts with LUKS-encrypted disks (e.g. `lambda`, `delta`) use
`fido2-device=auto` in their disko configs so the LUKS volume can be unlocked
with a FIDO2 token (such as a YubiKey) instead of typing a passphrase.

#### Enrolling a FIDO2 Token

FIDO2 tokens are **not** enrolled automatically! You must enroll them manually
after installation. Without enrollment the `Tokens:` section in `luksDump` will
be empty and the system will fall back to a password prompt.

```sh
# Main disk (contains root filesystem).
just fido2-enroll /dev/nvme0n1p3

# Extra disk (marked nofail, won't block boot).
just fido2-enroll /dev/nvme1n1p1
```

You can verify enrollment succeeded:

```sh
sudo cryptsetup luksDump /dev/nvme0n1p3 | grep -A5 'Tokens'
```

A successfully enrolled token will show a `systemd-fido2` entry under
`Tokens:` instead of an empty section.

#### Partition Labels

Disko generates systemd units that reference disks by GPT partition label
(e.g. `/dev/disk/by-partlabel/disk-extra-luks`). If a disk was partitioned
outside of disko the label may not exist and systemd will time out waiting for
it at boot.

To fix this, set the label manually (non-destructive, only changes the GPT
name, not data):

```sh
# For the extra NVMe:
sudo sgdisk -c 1:disk-extra-luks /dev/nvme1n1
```

#### Non-Essential Disks & `nofail`

The extra NVMe (`extra_lvm`) and backup (`/dev/sda`) volumes are marked with
`nofail` in both their crypttab and mount options. This means:

- If the disk is missing or its partition label doesn't exist, boot continues
  normally instead of hanging for 90 seconds and failing.
- The main disk (`luks_lvm`) intentionally does **not** have `nofail` because
  it contains `/`, `/nix`, and `/home`.

### Age Key Generation (sops-nix)

This config uses [sops-nix](https://github.com/Mic92/sops-nix) with
[age](https://github.com/FiloSottile/age)-format keys to manage secrets. There
are two kinds of access keys:

- **User key**: A standalone key for editing and maintaining `secrets.yaml`
  from any machine.
- **Host key**: Derived from the host's SSH ed25519 key so `sops-nix` can
  decrypt secrets during NixOS builds.

#### Generate a Standalone User Key

Create a personal age key at the default path `sops-nix` looks for:

```sh
just age-keygen
```

The public key is printed to the terminal. Back up the contents of `keys.txt`
somewhere safe (e.g. a password manager).

To re-print the public key later:

```sh
age-keygen -y ~/.config/sops/age/keys.txt
```

#### Derive a Host Key from SSH

Each NixOS host already has an SSH host key created when `openssh` is enabled.
Derive an age public key from it:

```sh
just age-host-key
```

> [!NOTE]
> The sops module in this config (`modules/nixosModules/features/sops.nix`)
> already points `sops.age.sshKeyPaths` at `/etc/ssh/ssh_host_ed25519_key` and
> sets `generateKey = true`, so the private side is handled automatically at
> activation time.

#### Register Keys in `.sops.yaml`

Add the public keys to the `.sops.yaml` file in your secrets repository:

```yaml
keys:
  - &user_alice age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  - &host_lambda age1yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy

creation_rules:
  - path_regex: secrets\.yaml$
    key_groups:
      - age:
          - *user_alice
          - *host_lambda
```

After updating `.sops.yaml`, re-encrypt `secrets.yaml` so the new keys can
access it:

```sh
sops updatekeys secrets.yaml
```

## Maintenance Guide

1. I recommend updating the [flake.lock](./flake.lock) file about once per week.

   ```sh
   just upgrade
   ```

> [!NOTE]
> If it can't build, roll back the [flake.lock](./flake.lock) file to a
> previous version and rebuild:
>
> ```sh
> just rollback
> ```

> [!TIP]
> The `rebuild` and `upgrade` commands accept extra arguments after the
> hostname. For example, to enable verbose trace output:
>
> ```sh
> just rebuild lambda --show-trace
> ```

### Rename Host

1. Move the host directory, e.g. `lambda` -> `epsilon`.

   ```sh
   mv modules/nixosModules/hosts/lambda modules/nixosModules/hosts/epsilon
   ```

2. Switch to new configuration.

   ```sh
   just rebuild epsilon
   ```

> [!WARNING]
> The hostname won't update automatically!  
> To update the hostname, either reboot the computer, or restart the current session.

### Add Host

1. Scaffold a new host from the minimal template.

   ```sh
   just add-host epsilon
   ```

2. Edit `modules/nixosModules/hosts/epsilon/configuration.nix` to add the
   modules and settings your new machine needs (hardware config, desktop,
   features, etc.). See `lambda` or `mu` for reference.

3. Build and switch to the new host.

   ```sh
   just rebuild epsilon
   ```

## To-Do Tracking

I track stuff I need to get done and stuff that annoys me about my current
setup in a file called [TODO.md](./TODO.md).  
If you have suggestions or notice something that could be improved, feel free
to open a pull request. I'll review and consider integrating your
contributions.

## Development Templates

You can use this flake for development environment templates.

### List Templates

```sh
nix-shell -p jq --run "nix flake show self --json 2>/dev/null | jq '.templates | map_values(.description) | del(.default)'"
```

### Use Template

> [!NOTE]
> Because we override the [Nix registry](https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-registry#description)  
> [here](./modules/nixos/nix/default.nix), we can simply use the `self` registry
> entry which references this flake.

### Rust Example

```sh
mkdir ~/Projects/example
cd ~/Projects/example

nix flake init -t self#rust
./init.sh
```
