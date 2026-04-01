{inputs, ...}: {
  flake.nixosModules.impermanence = {lib, ...}: {
    imports = [
      inputs.impermanence.nixosModules.impermanence
    ];

    # Persist essential system and user state across reboots so that fresh
    # installs behave identically to long-running systems.
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

      users.bastian = {
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

          # Firefox profile state (extensions, uBlock settings, etc.)
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
  };
}
