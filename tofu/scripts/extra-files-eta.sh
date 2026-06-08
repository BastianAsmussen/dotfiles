#!/usr/bin/env bash
set -euo pipefail
mkdir -p boot
sops -d --extract '["hosts"]["eta"]["initrd-ssh-private-key"]' ~/nix-secrets/hosts/eta.yaml > boot/initrd-host-key
chmod 600 boot/initrd-host-key
