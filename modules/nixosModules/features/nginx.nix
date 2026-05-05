{inputs, ...}: {
  flake.nixosModules.nginx = {
    lib,
    config,
    ...
  }: let
    inherit (lib) mkOption types mkIf mapAttrsToList;

    cfg = config.nginx;
    enabledProxies = lib.filterAttrs (_: proxy: proxy.enable) cfg.reverseProxies;
  in {
    options.nginx = {
      acme = {
        email = mkOption {
          type = types.str;
          default = config.preferences.user.email;
          description = "Email address used for ACME/Let's Encrypt certificate registration.";
        };

        sharedHost = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            When set, all reverse-proxy virtual hosts use this ACME certificate
            via useACMEHost instead of obtaining individual per-domain certificates.
            The certificate (typically a wildcard) must be declared separately via
            security.acme.certs.
          '';
        };
      };

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to open TCP ports 80 and 443 in the firewall.";
      };

      streamProxy = {
        enable = lib.mkEnableOption "TLS stream passthrough with static SNI routing";

        sniRoutes = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "Per-SNI upstream overrides: hostname → host:port.";
        };

        defaultUpstream = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Upstream (host:port) for unmatched SNI. When null, connections with
            unknown SNI are dropped. Ignored when stateFile is set (the state
            file owns the default entry in that case).
          '';
        };

        stateFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = ''
            Path to a mutable file included at the start of the SNI map block.
            The file may contain per-SNI entries and a default entry, all
            written by an external process (e.g. primaryMirror health check).
            When set, defaultUpstream is ignored. nginx must be reloaded after
            the file changes for them to take effect.
          '';
        };

        connectTimeout = mkOption {
          type = types.str;
          default = "3s";
          description = "Timeout for connecting to the upstream.";
        };
      };

      redirects = mkOption {
        default = {};
        description = "Set of domain redirect definitions. Each domain issues a 301 to the target URL.";
        type = types.attrsOf (types.submodule {
          options = {
            enable = lib.mkEnableOption "This nginx redirect virtual host.";

            domain = mkOption {
              type = types.str;
              description = "Source domain to redirect from (e.g. old-domain.com).";
            };

            target = mkOption {
              type = types.str;
              description = "Target URL to redirect to (e.g. https://asmussen.tech).";
            };

            forceSSL = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to redirect HTTP to HTTPS before issuing the domain redirect.";
            };

            ssl = mkOption {
              default = {};
              description = "SSL/TLS certificate configuration for this virtual host.";
              type = types.submodule {
                options = {
                  useACME = mkOption {
                    type = types.bool;
                    default = true;
                    description = "Obtain and renew a certificate automatically via ACME/Let's Encrypt.";
                  };

                  dnsProvider = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "ACME DNS-01 challenge provider (e.g. \"cloudflare\").";
                  };

                  environmentFile = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    description = "Path to an environment file with credentials for the DNS provider.";
                  };
                };
              };
            };
          };
        });
      };

      reverseProxies = mkOption {
        default = {};
        description = "Set of reverse proxy virtual host definitions for nginx with HTTPS support.";
        type = types.attrsOf (types.submodule ({name, ...}: {
          options = {
            enable = lib.mkEnableOption "This nginx reverse proxy virtual host.";

            domain = mkOption {
              type = types.str;
              description = "The domain name for this virtual host (e.g. foo.example.com).";
            };

            location = mkOption {
              type = types.str;
              default = "/${name}";
              description = ''
                URL path prefix at which this service is served.  Defaults to
                "/<name>" where <name> is the attribute key in reverseProxies
                (e.g. reverseProxies.foo -> "/foo").  Passed directly
                as an nginx `location` directive, which uses prefix matching by
                default. "/foo" matches "/foo", "/foo/bar", etc.
                Multiple services can share the same domain at different paths.
              '';
            };

            upstream = mkOption {
              type = types.str;
              description = "The upstream service URL to proxy requests to (e.g. http://localhost:8080).";
            };

            proxyWebsockets = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to enable WebSocket proxying support.";
            };

            forceSSL = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to redirect HTTP to HTTPS.";
            };

            ssl = mkOption {
              default = {};
              description = "SSL/TLS certificate configuration for this virtual host.";
              type = types.submodule {
                options = {
                  useACME = mkOption {
                    type = types.bool;
                    default = true;
                    description = "Obtain and renew a certificate automatically via ACME/Let's Encrypt.";
                  };

                  dnsProvider = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = ''
                      ACME DNS-01 challenge provider (e.g. "cloudflare").  When set,
                      certificates are validated via DNS instead of HTTP-01, so the
                      server does not need to be publicly reachable.  Requires
                      ssl.environmentFile to supply the provider's API credentials.
                    '';
                  };

                  environmentFile = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    description = ''
                      Path to an environment file with credentials for the DNS
                      provider in KEY=VALUE format (e.g. CF_DNS_API_TOKEN=...).
                      Use a sops template to wrap a raw secret in the correct
                      format, see the module header for an example.
                    '';
                  };

                  certificate = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    description = ''
                      Path to the TLS certificate file (PEM).  Only used when
                      ssl.useACME = false.  The certificate is public and may live
                      in the Nix store.
                    '';
                  };

                  certificateKey = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    description = ''
                      Path to the TLS private key file (PEM).  Only used when
                      ssl.useACME = false.  To keep the key out of the Nix store,
                      manage it with sops-nix and pass the resolved secret path:
                        sops.secrets."nginx-ssl-key".owner = "nginx";
                        ssl.certificateKey = config.sops.secrets."nginx-ssl-key".path;
                    '';
                  };
                };
              };
            };

            extraConfig = mkOption {
              type = types.lines;
              default = "";
              description = "Extra configuration to add to the nginx location block.";
            };

            mtls = mkOption {
              default = {};
              description = "Mutual TLS (client certificate verification) for this virtual host.";
              type = types.submodule {
                options = {
                  enable = lib.mkEnableOption "mTLS client certificate verification";

                  caCertificate = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    description = "Path to the CA certificate used to verify client certificates.";
                  };

                  localhostBypass = mkOption {
                    type = types.bool;
                    default = false;
                    description = ''
                      Allow requests from localhost (127.0.0.1, ::1) without a
                      valid client certificate.  Useful when a browser on the
                      same host should reach the service without importing the
                      client certificate.
                    '';
                  };
                };
              };
            };

            proxySSL = mkOption {
              default = {};
              description = "Client certificate to present when connecting to the upstream over TLS.";
              type = types.submodule {
                options = {
                  clientCertificate = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    description = "Path to the PEM client certificate for upstream mTLS.";
                  };

                  clientCertificateKey = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    description = "Path to the PEM private key for upstream mTLS.";
                  };

                  serverName = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = ''
                      Override the SNI hostname sent to the upstream during the
                      TLS handshake (proxy_ssl_name).  Required when the upstream
                      address differs from the domain the upstream expects (e.g.
                      when traffic is routed through an SNI-based passthrough
                      proxy at a different IP).  Enables proxy_ssl_server_name
                      automatically.
                    '';
                  };

                  verify = mkOption {
                    type = types.bool;
                    default = true;
                    description = "Whether to verify the upstream server's TLS certificate.";
                  };
                };
              };
            };
          };
        }));
      };
    };

    config = lib.mkMerge [
      (mkIf cfg.streamProxy.enable (let
        includeLines =
          lib.optional (cfg.streamProxy.stateFile != null)
          "include ${cfg.streamProxy.stateFile};";
        sniLines = lib.mapAttrsToList (host: addr: "${host} ${addr};") cfg.streamProxy.sniRoutes;
        defaultLine =
          lib.optional (cfg.streamProxy.stateFile == null && cfg.streamProxy.defaultUpstream != null)
          "default ${cfg.streamProxy.defaultUpstream};";
        mapEntries =
          lib.concatStringsSep "\n    "
          (includeLines ++ sniLines ++ defaultLine);
      in {
        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [80 443];

        services.nginx = {
          enable = true;
          streamConfig = ''
            map $ssl_preread_server_name $tls_backend {
              ${mapEntries}
            }

            server {
              listen 443;
              listen [::]:443;

              ssl_preread on;

              proxy_pass $tls_backend;
              proxy_connect_timeout ${cfg.streamProxy.connectTimeout};
            }
          '';

          virtualHosts."_stream_http_redirect" = {
            listen = [
              {
                addr = "0.0.0.0";
                port = 80;
              }
              {
                addr = "[::]";
                port = 80;
              }
            ];

            locations."/".return = "301 https://$host$request_uri";
          };
        };

        systemd.tmpfiles.rules = [
          "d /var/lib/primary-mirror 0775 root builder -"
        ];
      }))

      (mkIf (enabledProxies != {}) (let
        # Group proxies by domain so multiple services can share a single virtual
        # host at different URL paths.
        proxiesByDomain =
          lib.foldlAttrs (
            acc: _: proxy:
              acc
              // {
                ${proxy.domain} = (acc.${proxy.domain} or []) ++ [proxy];
              }
          ) {}
          enabledProxies;

        # For SSL / ACME configuration we pick the first proxy per domain, all
        # proxies on the same domain must agree on SSL settings (asserted below).
        representativeProxy = lib.mapAttrs (_: builtins.head) proxiesByDomain;
      in {
        assertions =
          (mapAttrsToList (name: proxy: {
              assertion =
                !proxy.forceSSL
                || proxy.ssl.useACME
                || (proxy.ssl.certificate != null && proxy.ssl.certificateKey != null);
              message = ''
                nginx.reverseProxies.${name}: forceSSL is enabled but neither
                ssl.useACME nor both ssl.certificate + ssl.certificateKey are set.
              '';
            })
            enabledProxies)
          ++ (mapAttrsToList (name: proxy: {
              assertion =
                proxy.ssl.dnsProvider == null || proxy.ssl.environmentFile != null;
              message = ''
                nginx.reverseProxies.${name}: ssl.dnsProvider is set but
                ssl.environmentFile is not.  The environment file must supply the
                provider's API credentials (e.g. CF_DNS_API_TOKEN=...).
              '';
            })
            enabledProxies)
          # All proxies that share a domain must agree on SSL settings.
          ++ (lib.concatLists (lib.mapAttrsToList (domain: proxies: let
            first = builtins.head proxies;
            rest = builtins.tail proxies;
          in
            map (p: {
              assertion =
                p.ssl.useACME
                == first.ssl.useACME
                && p.ssl.dnsProvider == first.ssl.dnsProvider
                && p.forceSSL == first.forceSSL
                && p.mtls.enable == first.mtls.enable;
              message = ''
                nginx: all reverseProxies sharing the domain "${domain}" must
                have identical ssl.useACME, ssl.dnsProvider, forceSSL, and
                mtls.enable settings.
              '';
            })
            rest)
          proxiesByDomain))
          ++ (mapAttrsToList (name: proxy: {
              assertion =
                !proxy.mtls.enable || proxy.mtls.caCertificate != null;
              message = ''
                nginx.reverseProxies.${name}: mtls.enable is set but
                mtls.caCertificate is not provided.
              '';
            })
            enabledProxies)
          ++ (mapAttrsToList (name: proxy: {
              assertion =
                (proxy.proxySSL.clientCertificate == null)
                == (proxy.proxySSL.clientCertificateKey == null);
              message = ''
                nginx.reverseProxies.${name}: proxySSL.clientCertificate and
                proxySSL.clientCertificateKey must both be set or both be null.
              '';
            })
            enabledProxies);

        sops =
          mkIf (
            lib.any (proxy: proxy.ssl.dnsProvider == "cloudflare") (lib.attrValues enabledProxies)
          ) {
            secrets."cloudflare-api-token".sopsFile = "${toString inputs.nix-secrets}/shared.yaml";
            templates."cloudflare-acme-env" = {
              owner = "acme";
              content = "CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare-api-token"}";
            };
          };

        security.acme =
          mkIf (
            lib.any (proxy: proxy.ssl.useACME) (lib.attrValues enabledProxies)
          ) {
            acceptTerms = true;
            defaults.email = cfg.acme.email;

            # DNS-01 challenge certificates need explicit cert entries.
            # Set group to the nginx service group so nginx can read the
            # obtained certificate files (useACMEHost certs default to the
            # "acme" group, which nginx cannot read).
            certs = builtins.listToAttrs (
              mapAttrsToList (_: proxy: {
                name = proxy.domain;
                value = {
                  inherit (proxy.ssl) dnsProvider environmentFile;
                  inherit (config.services.nginx) group;
                };
              })
              (lib.filterAttrs (
                  _: proxy:
                    proxy.ssl.useACME
                    && proxy.ssl.dnsProvider != null
                    && cfg.acme.sharedHost == null
                )
                representativeProxy)
            );
          };

        # Allow the ACME user to read DNS-01 credential files managed by sops-nix.
        users.users.acme.extraGroups = mkIf (
          lib.any (proxy: proxy.ssl.dnsProvider != null) (lib.attrValues enabledProxies)
        ) ["keys"];

        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [80 443];

        services.nginx = {
          enable = true;
          recommendedProxySettings = true;
          recommendedTlsSettings = true;
          recommendedGzipSettings = true;
          recommendedOptimisation = true;
          virtualHosts =
            lib.mapAttrs (domain: proxies: let
              # SSL settings come from the first proxy for this domain.
              rep = builtins.head proxies;
              useDns01 = rep.ssl.useACME && rep.ssl.dnsProvider != null;
              useShared = cfg.acme.sharedHost != null;
            in {
              inherit (rep) forceSSL;

              enableACME = !useShared && rep.ssl.useACME && !useDns01;
              useACMEHost =
                if useShared
                then cfg.acme.sharedHost
                else mkIf useDns01 domain;

              sslCertificate = mkIf (!rep.ssl.useACME && !useShared) rep.ssl.certificate;
              sslCertificateKey = mkIf (!rep.ssl.useACME && !useShared) rep.ssl.certificateKey;
              extraConfig = lib.optionalString rep.mtls.enable ''
                ssl_client_certificate ${rep.mtls.caCertificate};
                ssl_verify_client ${
                  if rep.mtls.localhostBypass
                  then "optional"
                  else "on"
                };
              '';

              # Merge locations from every proxy on this domain.
              locations = let
                proxyLocations = builtins.listToAttrs (map (proxy: {
                    name = proxy.location;
                    value = {
                      inherit (proxy) proxyWebsockets;

                      proxyPass = proxy.upstream;
                      extraConfig = lib.concatStringsSep "\n" (lib.filter (s: s != "") [
                        proxy.extraConfig
                        (lib.optionalString (proxy.proxySSL.clientCertificate != null) ''
                          proxy_ssl_certificate ${proxy.proxySSL.clientCertificate};
                          proxy_ssl_certificate_key ${proxy.proxySSL.clientCertificateKey};
                        '')
                        (lib.optionalString (proxy.proxySSL.serverName != null) ''
                          proxy_ssl_server_name on;
                          proxy_ssl_name ${proxy.proxySSL.serverName};
                        '')
                        (lib.optionalString (!proxy.proxySSL.verify) "proxy_ssl_verify off;")
                        (lib.optionalString (rep.mtls.enable && rep.mtls.localhostBypass) ''
                          if ($ssl_client_verify != SUCCESS) {
                            set $reject "no_cert";
                          }

                          if ($remote_addr = 127.0.0.1) {
                            set $reject "";
                          }

                          if ($remote_addr = ::1) {
                            set $reject "";
                          }

                          if ($reject) {
                            return 403;
                          }
                        '')
                      ]);
                    };
                  })
                  proxies);
                hasRoot = builtins.any (p: p.location == "/") proxies;
              in
                proxyLocations
                // lib.optionalAttrs (!hasRoot) {
                  "/".return = "404";
                };
            })
            proxiesByDomain;
        };
      }))

      (let
        enabledRedirects = lib.filterAttrs (_: r: r.enable) cfg.redirects;
        redirectList = lib.attrValues enabledRedirects;
        streamMode = cfg.streamProxy.enable;
      in
        mkIf (enabledRedirects != {}) (lib.mkMerge [
          {
            sops = mkIf (lib.any (r: r.ssl.dnsProvider == "cloudflare") redirectList) {
              secrets."cloudflare-api-token".sopsFile = "${toString inputs.nix-secrets}/shared.yaml";
              templates."cloudflare-acme-env" = {
                owner = "acme";
                content = "CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare-api-token"}";
              };
            };

            security.acme = mkIf (lib.any (r: r.ssl.useACME) redirectList) {
              acceptTerms = true;
              defaults.email = cfg.acme.email;
              certs = builtins.listToAttrs (
                mapAttrsToList (_: r: {
                  name = r.domain;
                  value = {
                    inherit (r.ssl) dnsProvider environmentFile;
                    inherit (config.services.nginx) group;
                  };
                })
                (lib.filterAttrs (_: r: r.ssl.useACME && r.ssl.dnsProvider != null) enabledRedirects)
              );
            };

            users.users.acme.extraGroups =
              mkIf (lib.any (r: r.ssl.dnsProvider != null) redirectList) ["keys"];

            networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [80 443];

            services.nginx.enable = true;
          }

          # Normal host: regular vhosts with ACME-managed certs.
          (mkIf (!streamMode) {
            services.nginx.virtualHosts =
              lib.mapAttrs' (_: r: let
                useDns01 = r.ssl.useACME && r.ssl.dnsProvider != null;
              in {
                name = r.domain;
                value = {
                  inherit (r) forceSSL;

                  enableACME = r.ssl.useACME && !useDns01;
                  useACMEHost = mkIf useDns01 r.domain;
                  locations."/".return = "301 ${r.target}$request_uri";
                };
              })
              enabledRedirects;
          })
        ]))
    ];
  };
}
