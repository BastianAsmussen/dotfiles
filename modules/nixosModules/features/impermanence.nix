{inputs, ...}: {
  flake.nixosModules.impermanence = {lib, ...}: {
    imports = [
      inputs.impermanence.nixosModules.impermanence
    ];

    # On a btrfs root, the recommended approach is to create a blank snapshot
    # of the root subvolume at install time:
    #
    #   btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
    #
    # Then on every boot, roll back the root subvolume to the blank snapshot
    # so that only explicitly persisted state survives reboots.
    boot.initrd.postResumeCommands = lib.mkAfter ''
      mkdir -p /mnt
      mount -o subvol=/ /dev/mapper/luks_lvm-root /mnt

      if [ -e /mnt/root-blank ]; then
        btrfs subvolume delete /mnt/root/old_root 2>/dev/null || true
        mv /mnt/root /mnt/root/old_root 2>/dev/null || true
        btrfs subvolume snapshot /mnt/root-blank /mnt/root
      fi

      umount /mnt
    '';

    # Persist essential system state. Paths listed here are bind-mounted from
    # /nix/persist into the ephemeral root, so they survive the snapshot
    # rollback above.
    environment.persistence."/nix/persist" = {
      hideMounts = true;

      directories = [
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/tailscale"
        "/etc/NetworkManager/system-connections"
      ];

      files = [
        "/etc/machine-id"
      ];
    };

    # Home Manager impermanence is configured separately in the home module
    # below so that it tracks the user's own state directories.
  };

  flake.homeModules.impermanence = {
    imports = [
      inputs.impermanence.homeManagerModules.impermanence
    ];

    home.persistence."/nix/persist/home/bastian" = {
      allowOther = true;

      directories = [
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Projects"
        "Videos"
        ".local/share/direnv"
        ".local/state/nvim"
        ".local/share/nvim"
        ".local/state/zsh"

        # Firefox profile state (extensions, uBlock Origin settings, etc.)
        ".mozilla"

        # GPG and SSH agent state.
        ".gnupg"

        # Password store.
        ".local/share/password-store"

        # Discord state.
        {
          directory = ".config/discord";
          mode = "0700";
        }

        # Spotify state.
        ".config/spotify"
      ];

      files = [
        ".config/monitors.xml"
      ];
    };
  };
}
