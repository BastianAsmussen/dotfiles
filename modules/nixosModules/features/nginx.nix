{
  flake.nixosModules.nginx = {
    lib,
    config,
    ...
  }: let
    inherit (lib) mkOption types mkIf mapAttrsToList;

    cfg = config.nginx;
    enabledProxies = lib.filterAttrs (_: proxy: proxy.enable) cfg.reverseProxies;

    streamStateFile = "/var/lib/primary-mirror/stream-upstream.conf";
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
        enable = lib.mkEnableOption "TLS stream passthrough with dynamic upstream switching";

        upstream = mkOption {
          type = types.str;
          description = "Primary upstream (host:port) for TLS passthrough.";
        };

        fallbackPort = mkOption {
          type = types.nullOr types.port;
          default = null;
          description = "Loopback port serving as backup when the primary upstream is unavailable.";
        };

        connectTimeout = mkOption {
          type = types.str;
          default = "3s";
          description = "Timeout for connecting to the upstream before trying the fallback.";
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
                (e.g. reverseProxies.foo → "/foo").  Passed directly
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
          };
        }));
      };
    };

    config = lib.mkMerge [
      (mkIf cfg.streamProxy.enable {
        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [80 443];

        services.nginx = {
          enable = true;

          streamConfig = ''
            upstream tls_passthrough {
              include ${streamStateFile};
              ${lib.optionalString (cfg.streamProxy.fallbackPort != null)
              "server 127.0.0.1:${toString cfg.streamProxy.fallbackPort} backup;"}
            }
            server {
              listen 443;
              proxy_pass tls_passthrough;
              ssl_preread on;
              proxy_connect_timeout ${cfg.streamProxy.connectTimeout};
            }
          '';

          virtualHosts."_stream_http_redirect" = {
            listen = [
              {
                addr = "0.0.0.0";
                port = 80;
              }
            ];
            locations."/".return = "301 https://$host$request_uri";
          };
        };

        systemd.tmpfiles.rules = [
          "d /var/lib/primary-mirror 0775 root builder -"
          "f ${streamStateFile} 0644 root root - 'server ${cfg.streamProxy.upstream} down;'"
        ];
      })

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
                && p.forceSSL == first.forceSSL;
              message = ''
                nginx: all reverseProxies sharing the domain "${domain}" must
                have identical ssl.useACME, ssl.dnsProvider, and forceSSL
                settings.
              '';
            })
            rest)
          proxiesByDomain));

        sops =
          mkIf (
            lib.any (proxy: proxy.ssl.dnsProvider == "cloudflare") (lib.attrValues enabledProxies)
          ) {
            secrets."cloudflare-api-token" = {};
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

              # Merge locations from every proxy on this domain.
              locations = let
                proxyLocations = builtins.listToAttrs (map (proxy: {
                    name = proxy.location;
                    value = {
                      inherit (proxy) proxyWebsockets extraConfig;

                      proxyPass = proxy.upstream;
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
              secrets."cloudflare-api-token" = {};
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

          # Stream-proxy host: serve redirects on the local fallback port so they
          # work when the primary upstream (epsilon) is unreachable.
          (mkIf streamMode {
            services.nginx.virtualHosts =
              lib.mapAttrs' (_: r: {
                name = r.domain;
                value = {
                  listen = [
                    {
                      addr = "127.0.0.1";
                      port = cfg.streamProxy.fallbackPort;
                      ssl = true;
                    }
                  ];
                  extraConfig = ''
                    ssl_certificate /var/lib/acme/${r.domain}/fullchain.pem;
                    ssl_certificate_key /var/lib/acme/${r.domain}/key.pem;
                  '';
                  locations."/".return = "301 ${r.target}$request_uri";
                };
              })
              enabledRedirects;
          })

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
