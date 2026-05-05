{
  flake.nixosModules.i2p = {
    config,
    lib,
    ...
  }: {
    options.i2p = {
      enable = lib.mkEnableOption "I2P router daemon (i2pd).";
      floodfill = lib.mkEnableOption "Floodfill router mode.";
      openFirewall = lib.mkEnableOption "Open I2P transport ports in the firewall.";
      eepsite = {
        enable = lib.mkEnableOption "I2P eepsite hidden web server.";
        port = lib.mkOption {
          type = lib.types.port;
          default = 7658;
          description = "Local port nginx listens on for eepsite traffic.";
        };
      };
    };

    config = lib.mkMerge [
      (lib.mkIf config.i2p.enable {
        services.i2pd = {
          enable = true;

          inherit (config.i2p) floodfill;

          # Transit tunnels are useful for relays but wasteful for clients.
          notransit = !config.i2p.floodfill;
          proto = {
            http.enable = true;
            httpProxy.enable = true;
            socksProxy.enable = true;
            sam.enable = true;
            i2cp = {
              enable = true;
              address = "127.0.0.1";
            };
          };
        };
      })

      # Floodfill nodes need stable ports and declared bandwidth so they are
      # reachable and trusted by the network.
      (lib.mkIf (config.i2p.enable && config.i2p.floodfill) {
        services.i2pd = {
          bandwidth = 1024;
          ntcp2 = {
            published = true;
            port = 4567;
          };

          ssu2 = {
            published = true;
            port = 4568;
          };
        };
      })

      # Eepsite: i2pd HTTP tunnel -> loopback nginx -> /var/www/eepsite.
      (lib.mkIf (config.i2p.enable && config.i2p.eepsite.enable) {
        sops.secrets."hosts/${config.networking.hostName}/i2p-eepsite-key" = {
          owner = "i2pd";
          mode = "0600";
          path = "/var/lib/i2pd/eepsite.dat";
        };

        services.i2pd.inTunnels.eepsite = {
          inherit (config.i2p.eepsite) port;

          enable = true;
          address = "127.0.0.1";
          keys = "eepsite.dat";
          type = "http";
        };

        services.nginx = {
          enable = lib.mkDefault true;
          virtualHosts."eepsite" = {
            listen = [
              {
                inherit (config.i2p.eepsite) port;

                addr = "127.0.0.1";
                ssl = false;
              }
            ];

            root = "/var/www/eepsite";
          };
        };

        systemd.tmpfiles.rules = ["d /var/www/eepsite 0755 nginx nginx -"];
      })

      (lib.mkIf config.i2p.openFirewall {
        networking.firewall = {
          allowedTCPPorts = [4567];
          allowedUDPPorts = [4568];
        };
      })
    ];
  };
}
