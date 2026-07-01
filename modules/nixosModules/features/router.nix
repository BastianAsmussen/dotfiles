{
  flake.nixosModules.router =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        mkOption
        mkEnableOption
        mkIf
        types
        ;

      cfg = config.router;

      # Firmware schema extracted from a real i4850-20 backup. It pins the
      # opaque 1 KiB header, the fixed checksum descriptor, and the ordered
      # record list (key/len/type/kind + firmware defaults). Records flagged
      # `secret` carry no value here; their bytes come from sops at run time.
      template = builtins.fromJSON (builtins.readFile ./router.template.json);

      generator = ./router.generate.py;
      python = "${pkgs.python3}/bin/python3";

      # The firmware exposes a fixed number of slots for these tables.
      maxLeases = 4;
      maxForwards = 3;

      # MAC/IPv4 validators and the MAC normaliser live in lib.custom.net
      # (modules/lib/net.nix), unit-tested under modules/tests/net.
      inherit (lib.custom.net) isIPv4 isMac normMac;

      # DHCP advertises up to two DNS servers. An empty list falls back to the
      # router itself rather than silently advertising no resolver; the result
      # is truncated to two, padding the short form with 0.0.0.0.
      dnsList = if cfg.dns == [ ] then [ cfg.host ] else cfg.dns;
      dnsPair = lib.take 2 (dnsList ++ [ "0.0.0.0" ]);

      # Expand the static-lease list into the 4 firmware slots. Slots the user
      # does not fill are explicitly disabled so options stay authoritative
      # (otherwise the baked firmware default for slot 1 would leak through).
      leaseOverrides = lib.foldl' (
        acc: i:
        let
          prefix = "DHCPv4.Server.Pool.1.StaticAddress.${toString (i + 1)}";
          entry =
            if i < builtins.length cfg.dhcp.staticLeases then
              let
                lease = builtins.elemAt cfg.dhcp.staticLeases i;
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
      ) { } (lib.range 0 (maxLeases - 1));

      # Only tcp (1) is verified against the device; udp/tcp-udp codes are
      # inferred and should be confirmed before relying on a non-tcp rule.
      protocolCodes = {
        tcp = 1;
        udp = 2;
        "tcp-udp" = 3;
      };

      forwardOverrides = lib.foldl' (
        acc: i:
        let
          prefix = "NAT.PortMapping.${toString (i + 1)}";
          entry =
            if i < builtins.length cfg.portForwards then
              let
                fwd = builtins.elemAt cfg.portForwards i;
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
      ) { } (lib.range 0 (maxForwards - 1));

      scalarOverrides = {
        "UserInterface.X_GETOUI_Leds.AutoOffState?" = cfg.leds.autoOff;
        "DHCPv4.Server.Pool.1.DnsServers?" = dnsPair;
        "X_GETOUI_UPnP.Enable?" = if cfg.upnp.enable then 1 else 0;
        "WiFi.SSID.1.SSID?" = cfg.wifi.ssid;
        "WiFi.SSID.5.SSID?" = cfg.wifi.ssid;
      };

      overrides = scalarOverrides // leaseOverrides // forwardOverrides;

      # sops-provided values for the records the schema marks secret.
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
            Path to a file holding the router web/admin password (a sops
            secret). Used both to log in for a restore and as the
            CustomerPassword written into the pushed configuration.
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
          defaultText = lib.literalExpression "[ config.router.host ]";
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
                enable = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Whether this reservation is active.";
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
                    defaultText = lib.literalExpression "config.externalPort";
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
                      Transport protocol. Only tcp is verified against the
                      device; udp and tcp-udp codes are inferred.
                    '';
                  };
                  enable = mkOption {
                    type = types.bool;
                    default = true;
                    description = "Whether this rule is active.";
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
            assertion = builtins.length cfg.dhcp.staticLeases <= maxLeases;
            message = "router.dhcp.staticLeases supports at most ${toString maxLeases} entries.";
          }
          {
            assertion = builtins.length cfg.portForwards <= maxForwards;
            message = "router.portForwards supports at most ${toString maxForwards} entries.";
          }
          {
            assertion = builtins.length cfg.dns <= 2;
            message = "router.dns advertises at most two DNS servers.";
          }
          {
            assertion = builtins.all isIPv4 dnsList;
            message = "router.dns entries must be IPv4 addresses.";
          }
          {
            assertion = builtins.all (l: isMac l.mac) cfg.dhcp.staticLeases;
            message = "router.dhcp.staticLeases: every mac must be a 6-octet hex MAC (colon or dash separated).";
          }
          {
            assertion = builtins.all (l: isIPv4 l.ip) cfg.dhcp.staticLeases;
            message = "router.dhcp.staticLeases: every ip must be an IPv4 address.";
          }
          {
            assertion = builtins.all (f: isIPv4 f.internalClient) cfg.portForwards;
            message = "router.portForwards: every internalClient must be an IPv4 address.";
          }
        ];

        # Both units are manual-only (no wantedBy): the router is a live,
        # externally-owned device, so pushing config is always a deliberate
        # act, never something that fires on boot or activation.
        systemd.services = {
          router-config-generate = {
            description = "Render the declarative Icotera router backup (no upload)";
            serviceConfig = {
              Type = "oneshot";
              StateDirectory = "icotera-router";
              # The rendered backup embeds the cleartext admin password and WPA
              # passphrase, so keep the directory and file root-only (the script
              # also chmods the file 0600 as a belt-and-braces guard).
              StateDirectoryMode = "0700";
              UMask = "0077";
              ExecStart = "${python} ${generator} generate ${planFile} /var/lib/icotera-router/config-backup.bin";
            };
          };

          # Restore uploads over plain HTTP (mini_httpd has no TLS), so it must
          # stay strictly LAN-local. It validates the device's response and
          # fails the unit on a rejected or unreachable push.
          router-config-push = {
            description = "Restore the declarative config to the live Icotera router";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${python} ${generator} push ${planFile}";
            };
          };
        };
      };
    };
}
