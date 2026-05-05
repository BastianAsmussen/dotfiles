{inputs, ...}: {
  flake.nixosModules.syncthing = {
    config,
    lib,
    ...
  }: let
    inherit (inputs.nix-secrets) hosts;

    user = config.preferences.user.name;
    home = "/home/${user}";
    devices = {
      epsilon.id = hosts.epsilon.syncthing-id;
      delta.id = hosts.delta.syncthing-id;
      mu.id = hosts.mu.syncthing-id;
    };

    # All hosts share the same folder declarations; each host syncs with the
    # other devices in the list (Syncthing silently ignores its own ID).
    allDevices = lib.attrNames devices;
  in {
    # Expose Syncthing as an I2P hidden service when i2pd is running.
    # The key determines the stable B32 address.
    services.i2pd.inTunnels = lib.mkIf config.services.i2pd.enable {
      syncthing = {
        enable = true;
        address = "127.0.0.1";
        port = 22000;
        keys = "syncthing-i2p.dat";
      };
    };

    sops.secrets = {
      "services/syncthing/gui-password" = {
        sopsFile = "${toString inputs.nix-secrets}/shared.yaml";
        owner = user;
      };

      "hosts/${config.networking.hostName}/syncthing-key".owner = user;
      "hosts/${config.networking.hostName}/syncthing-cert".owner = user;
      "hosts/${config.networking.hostName}/i2p-syncthing-key" = {
        owner = "i2pd";
        mode = "0600";
        path = "/var/lib/i2pd/syncthing-i2p.dat";
      };
    };

    services.syncthing = {
      inherit user;

      enable = true;
      group = "users";
      dataDir = home;
      cert = config.sops.secrets."hosts/${config.networking.hostName}/syncthing-cert".path;
      key = config.sops.secrets."hosts/${config.networking.hostName}/syncthing-key".path;
      guiPasswordFile = config.sops.secrets."services/syncthing/gui-password".path;
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        inherit devices;

        options.urAccepted = -1;
        gui = {
          inherit user;

          insecureSkipHostcheck = true;
          theme = "dark";
        };

        folders = {
          "Documents" = {
            path = "${home}/Documents";
            devices = allDevices;
          };

          "Pictures" = {
            path = "${home}/Pictures";
            devices = allDevices;
          };

          "Videos" = {
            path = "${home}/Videos";
            devices = ["epsilon" "delta"];
          };
        };
      };
    };
  };
}
