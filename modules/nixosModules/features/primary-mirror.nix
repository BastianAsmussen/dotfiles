{
  flake.nixosModules.primaryMirror =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        concatStringsSep
        mkEnableOption
        mkIf
        mkOption
        optionalString
        types
        ;

      cfg = config.primaryMirror;

      fallbackAddress = "127.0.0.1:${toString config.caddy.defaultPort}";
    in
    {
      options.primaryMirror = {
        enable = mkEnableOption ''
          SNI passthrough to the primary host, failing over to this host's own
          Caddy on the loopback fallback listener while the primary is down or
          busy
        '';

        primaryHost = mkOption {
          type = types.str;
          default = "10.10.0.2";
          description = "WireGuard address of the primary host.";
        };

        primaryPort = mkOption {
          type = types.port;
          default = 443;
          description = "Primary listener that accepts PROXY headers from this host.";
        };

        mtlsPort = mkOption {
          type = types.port;
          default = 8443;
          description = "Primary listener that requires client certificates and takes no PROXY header.";
        };

        availabilityPort = mkOption {
          type = types.port;
          default = 9444;
          description = "Port the health check dials; the primary closes it while busy.";
        };

        healthInterval = mkOption {
          type = types.str;
          default = "10s";
          description = "How often to dial the availability port.";
        };

        mtlsNames = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "SNI names passed through to the client-certificate listener, with no failover.";
        };

        passthroughNames = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "SNI names passed through to the primary with a PROXY header, failing over locally.";
        };
      };

      config = mkIf cfg.enable {
        caddy.servers = {
          # Routes run in order; anything unmatched is terminated by this host.
          ":443" = ''
            listener_wrappers {
              layer4 {
                ${optionalString (cfg.mtlsNames != [ ]) ''
                  @mtls tls sni ${concatStringsSep " " cfg.mtlsNames}
                  route @mtls {
                    proxy ${cfg.primaryHost}:${toString cfg.mtlsPort}
                  }
                ''}

                @primary tls sni ${concatStringsSep " " cfg.passthroughNames}
                route @primary {
                  proxy {
                    proxy_protocol v2
                    lb_policy first
                    health_port ${toString cfg.availabilityPort}
                    health_interval ${cfg.healthInterval}
                    health_timeout 3s
                    fail_duration 30s
                    upstream ${cfg.primaryHost}:${toString cfg.primaryPort}
                    upstream ${fallbackAddress}
                  }
                }
              }

              tls
            }
          '';

          ${fallbackAddress} = ''
            listener_wrappers {
              proxy_protocol {
                allow 127.0.0.1/32
              }

              tls
            }
          '';
        };

        # The health check covers every upstream, the local fallback included.
        systemd = {
          sockets.primary-mirror-fallback = {
            description = "Always-open availability probe for the local fallback";
            wantedBy = [ "sockets.target" ];
            listenStreams = [ "127.0.0.1:${toString cfg.availabilityPort}" ];
            socketConfig.Accept = true;
          };

          services."primary-mirror-fallback@" = {
            description = "Close a local fallback availability probe";
            serviceConfig = {
              ExecStart = lib.getExe' pkgs.coreutils "true";
              StandardInput = "socket";
            };
          };
        };
      };
    };
}
