#!/usr/bin/env bash
set -euo pipefail

# Initrd SSH host key (port 2222 LUKS unlock). Lands in /boot.
mkdir -p boot
sops -d --extract '["hosts"]["eta"]["initrd-ssh-private-key"]' ~/nix-secrets/hosts/eta.yaml > boot/initrd-host-key
chmod 600 boot/initrd-host-key

# Persistent SSH host key = eta's sops age identity. On a tmpfs root it must be
# seeded onto /persist (not /etc/ssh, which is wiped each boot) so sops-nix can
# derive the age key at activation. preservation bind-mounts this to /etc/ssh.
install -d -m 0755 persist/system/etc/ssh
sops -d --extract '["hosts"]["eta"]["ssh-private-key"]' ~/nix-secrets/hosts/eta.yaml > persist/system/etc/ssh/ssh_host_ed25519_key
chmod 600 persist/system/etc/ssh/ssh_host_ed25519_key
ssh-keygen -y -f persist/system/etc/ssh/ssh_host_ed25519_key > persist/system/etc/ssh/ssh_host_ed25519_key.pub
chmod 644 persist/system/etc/ssh/ssh_host_ed25519_key.pub
