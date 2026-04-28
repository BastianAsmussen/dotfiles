{
  flake.nixosModules.wireguard = {
    lib,
    config,
    ...
  }: let
    inherit (lib) mkOption mkEnableOption mkIf types;

    cfg = config.wireguard;
  in {
    options.wireguard = {
      enable = mkEnableOption "WireGuard VPN interface";

      interface = mkOption {
        type = types.str;
        default = "wg0";
        description = "WireGuard network interface name.";
      };

      ips = mkOption {
        type = types.listOf types.str;
        description = "IP addresses (CIDR) assigned to the WireGuard interface.";
      };

      listenPort = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = ''
          UDP port to listen on.  Set for server/relay role; null lets
          WireGuard pick an ephemeral port (appropriate for outbound-only peers).
        '';
      };

      peers = mkOption {
        default = [];
        description = "WireGuard peers.";
        type = types.listOf (types.submodule ({config, ...}: {
          options = {
            publicKey = mkOption {
              type = types.str;
              description = "WireGuard public key of the peer.";
            };

            peerIps = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "The raw wireguard.ips array of the peer to automatically compute allowedIPs from.";
            };

            allowedIPs = mkOption {
              type = types.listOf types.str;
              default = map (ip: let
                addr = builtins.head (lib.splitString "/" ip);
                mask =
                  if lib.hasInfix ":" addr
                  then "128"
                  else "32";
              in "${addr}/${mask}")
              config.peerIps;
              description = "Allowed source IP ranges for traffic from this peer (CIDR). Defaults to strict host routing based on peerIps.";
            };

            endpoint = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Peer endpoint as host:port. Set when we initiate the connection.";
            };

            persistentKeepalive = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = "Keepalive interval in seconds. Recommended for peers behind NAT.";
            };

            presharedKeyFile = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Path to pre-shared key file for this peer. Provides post-quantum resistance.";
            };
          };
        }));
      };
    };

    config = mkIf cfg.enable (let
      secretName = "hosts/${config.networking.hostName}/wireguard-private-key";
    in {
      sops.secrets.${secretName} = {};

      networking = {
        wireguard.interfaces.${cfg.interface} = {
          inherit (cfg) ips listenPort;

          privateKeyFile = config.sops.secrets.${secretName}.path;
          peers =
            map (peer: {
              inherit (peer) publicKey allowedIPs endpoint persistentKeepalive presharedKeyFile;
            })
            cfg.peers;
        };

        firewall.allowedUDPPorts = mkIf (cfg.listenPort != null) [cfg.listenPort];
      };
    });
  };
}
