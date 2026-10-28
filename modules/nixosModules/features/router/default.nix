{
  flake.nixosModules.router =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (builtins)
        readFile
        length
        elemAt
        all
        ;

      inherit (lib)
        foldl'
        range
        mkOption
        mkEnableOption
        mkIf
        types
        literalExpression
        ;

      inherit (lib.custom.net) isIPv4 isMac normMac;

      cfg = config.router;
      generator = pkgs.writers.writePython3Bin "router-generate" { } (readFile ./generate.py);

      # Firmware schema reverse-engineered from a real i4850-20 router backup.
      template = builtins.fromJSON (readFile ./template.json);

      # Firmware exposed a fixed number of slots for these.
      maxLeases = 4;
      maxForwards = 3;

      dnsList = if cfg.dns == [ ] then [ cfg.host ] else cfg.dns;
      dnsPair = lib.take 2 (dnsList ++ [ "0.0.0.0" ]);

      leaseOverrides = foldl' (
        acc: i:
        let
          prefix = "DHCPv4.Server.Pool.1.StaticAddress.${toString (i + 1)}";
          entry =
            if i < length cfg.dhcp.staticLeases then
              let
                lease = elemAt cfg.dhcp.staticLeases i;
              in
              {
                "${prefix}.Enable?" = if lease.enable then 1 else 0;
                "${prefix}.Chaddr?" = normMac lease.mac;
                "${prefix}.YiAddr?" = lease.ip;
                "${prefix}.Hostname?" = lease.hostname;
              }
            else
              {
                "${prefix}.Enable?" = 0;
                "${prefix}.Chaddr?" = "";
                "${prefix}.YiAddr?" = "0.0.0.0";
                "${prefix}.Hostname?" = "";
              };
        in
        acc // entry
      ) { } (range 0 (maxLeases - 1));

      protocolCodes = {
        tcp = 1;
        udp = 2;
        "tcp-udp" = 3;
      };

      forwardOverrides = foldl' (
        acc: i:
        let
          prefix = "NAT.PortMapping.${toString (i + 1)}";
          entry =
            if i < length cfg.portForwards then
              let
                fwd = elemAt cfg.portForwards i;
              in
              {
                "${prefix}.Enable?" = if fwd.enable then 1 else 0;
                "${prefix}.Alias?" = fwd.name;
                "${prefix}.InternalClient?" = fwd.internalClient;
                "${prefix}.ExternalPort?" = fwd.externalPort;
                "${prefix}.InternalPort?" = fwd.internalPort;
                "${prefix}.Protocol?" = protocolCodes.${fwd.protocol};
              }
            else
              {
                "${prefix}.Enable?" = 0;
                "${prefix}.Alias?" = "";
                "${prefix}.InternalClient?" = "0.0.0.0";
                "${prefix}.ExternalPort?" = 0;
                "${prefix}.InternalPort?" = 0;
                "${prefix}.Protocol?" = 1;
              };
        in
        acc // entry
      ) { } (range 0 (maxForwards - 1));

      scalarOverrides = {
        "UserInterface.X_GETOUI_Leds.AutoOffState?" = cfg.leds.autoOff;
        "DHCPv4.Server.Pool.1.DnsServers?" = dnsPair;
        "X_GETOUI_UPnP.Enable?" = if cfg.upnp.enable then 1 else 0;
        "WiFi.SSID.1.SSID?" = cfg.wifi.ssid;
        "WiFi.SSID.5.SSID?" = cfg.wifi.ssid;
      };

      overrides = scalarOverrides // leaseOverrides // forwardOverrides;
      secretFiles = {
        "UserInterface.X_GETOUI_WEB.CustomerPassword?" = cfg.adminPasswordFile;
        "WiFi.AccessPoint.1.Security.KeyPassphrase?" = cfg.wifi.passphraseFile;
        "WiFi.AccessPoint.5.Security.KeyPassphrase?" = cfg.wifi.passphraseFile;
      };

      planRecords = map (
        record:
        let
          base = {
            inherit (record)
              key
              len
              type
              kind
              ;
          };
        in
        if record.secret or false then
          base // { secretFile = secretFiles.${record.key}; }
        else
          base // { value = overrides.${record.key} or record.default; }
      ) template.records;

      plan = {
        inherit (cfg) host;
        inherit (template) header_b64 checksum_b64;

        records = planRecords;
        login = {
          user = cfg.adminUser;
          passwordFile = cfg.adminPasswordFile;
        };
      };

      planFile = pkgs.writeText "icotera-router-plan.json" (builtins.toJSON plan);
    in
    {
      options.router = {
        enable = mkEnableOption "declarative Icotera i4850-20 router configuration";
        host = mkOption {
          type = types.str;
          default = "192.168.1.254";
          description = "Address of the router's GETOUI web panel.";
        };

        adminUser = mkOption {
          type = types.str;
          default = "admin";
          description = "Web-panel login user.";
        };

        adminPasswordFile = mkOption {
          type = types.path;
          description = ''
            Path to a file holding the router web/admin password.
            Used both to log in for a restore and as the CustomerPassword
            written into the live config.
          '';
        };

        leds.autoOff = mkOption {
          type = types.ints.u8;
          default = 3;
          description = "GETOUI LED auto-off state (firmware value; 3 as shipped).";
        };

        upnp.enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether the router advertises UPnP IGD.";
        };

        dns = mkOption {
          type = types.listOf types.str;
          default = [ cfg.host ];
          defaultText =
            literalExpression
              # nix
              "[ config.router.host ]";
          description = "Up to two DNS servers advertised to LAN DHCP clients.";
        };

        wifi = {
          ssid = mkOption {
            type = types.str;
            description = "WiFi network name (applied to both the 2.4 and 5 GHz radios).";
          };

          passphraseFile = mkOption {
            type = types.path;
            description = "Path to a file holding the WPA passphrase (a sops secret).";
          };
        };

        dhcp.staticLeases = mkOption {
          default = [ ];
          description = "Static DHCP reservations (at most ${toString maxLeases}).";
          type = types.listOf (
            types.submodule {
              options = {
                enable = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Whether this reservation is active.";
                };

                hostname = mkOption {
                  type = types.str;
                  description = "Hostname recorded for the reservation.";
                };

                mac = mkOption {
                  type = types.str;
                  example = "c8:7f:54:66:ff:72";
                  description = "Client MAC address (lowercase, colon-separated).";
                };

                ip = mkOption {
                  type = types.str;
                  example = "192.168.1.64";
                  description = "Address to hand out to that MAC.";
                };
              };
            }
          );
        };

        portForwards = mkOption {
          default = [ ];
          description = "NAT port-forwarding rules (at most ${toString maxForwards}).";
          type = types.listOf (
            types.submodule (
              { config, ... }:
              {
                options = {
                  enable = mkOption {
                    type = types.bool;
                    default = true;
                    description = "Whether this rule is active.";
                  };

                  name = mkOption {
                    type = types.str;
                    description = "Human-readable alias for the rule.";
                  };

                  internalClient = mkOption {
                    type = types.str;
                    description = "LAN address the traffic is forwarded to.";
                  };

                  externalPort = mkOption {
                    type = types.port;
                    description = "Port exposed on the WAN side.";
                  };

                  internalPort = mkOption {
                    type = types.port;
                    default = config.externalPort;
                    defaultText = literalExpression "config.externalPort";
                    description = "Port on the internal client (defaults to externalPort).";
                  };

                  protocol = mkOption {
                    type = types.enum [
                      "tcp"
                      "udp"
                      "tcp-udp"
                    ];

                    default = "tcp";
                    description = ''
                      Transport protocol. Only `tcp` is verified against the
                      device. `udp and `tcp-udp` codes are inferred.
                    '';
                  };
                };
              }
            )
          );
        };
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = length cfg.dhcp.staticLeases <= maxLeases;
            message = "router.dhcp.staticLeases supports at most ${toString maxLeases} entries.";
          }
          {
            assertion = length cfg.portForwards <= maxForwards;
            message = "router.portForwards supports at most ${toString maxForwards} entries.";
          }
          {
            assertion = length cfg.dns <= 2;
            message = "router.dns advertises at most two DNS servers.";
          }
          {
            assertion = all isIPv4 dnsList;
            message = "router.dns entries must be IPv4 addresses.";
          }
          {
            assertion = all (l: isMac l.mac) cfg.dhcp.staticLeases;
            message = "router.dhcp.staticLeases: every mac must be a 6-octet hex MAC (colon or dash separated).";
          }
          {
            assertion = all (l: isIPv4 l.ip) cfg.dhcp.staticLeases;
            message = "router.dhcp.staticLeases: every ip must be an IPv4 address.";
          }
          {
            assertion = all (f: isIPv4 f.internalClient) cfg.portForwards;
            message = "router.portForwards: every internalClient must be an IPv4 address.";
          }
        ];

        systemd.services = {
          router-config-generate = {
            description = "Render the declarative Icotera router backup";
            serviceConfig = {
              Type = "oneshot";
              StateDirectory = "icotera-router";
              StateDirectoryMode = "0700";
              UMask = "0077";
              ExecStart = "${generator} generate ${planFile} /var/lib/icotera-router/config-backup.bin";
            };
          };

          router-config-push = {
            description = "Restore the declarative config to the live Icotera router";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${generator} push ${planFile}";
            };
          };
        };
      };
    };
}
