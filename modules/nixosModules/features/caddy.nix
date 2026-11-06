{ withSystem, ... }:
{
  flake.nixosModules.caddy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        mkDefault
        mkEnableOption
        mkIf
        mkOption
        types
        ;

      cfg = config.caddy;
      vhosts = lib.attrValues config.services.caddy.virtualHosts;

      # Extract a hostname from HTTPS virtual-host addresses.
      hostOf =
        address:
        let
          host = lib.head (lib.splitString ":" (lib.removePrefix "https://" address));
          bare = lib.removePrefix "*." host;
        in
        if lib.hasPrefix "http://" address || builtins.match "([a-z0-9-]+\\.)+[a-z]+" bare == null then
          null
        else
          bare;

      # Use the last two labels as the apex domain.
      apexOf =
        host:
        let
          labels = lib.splitString "." host;
        in
        lib.concatStringsSep "." (lib.sublist (lib.length labels - 2) 2 labels);

      certOf = address: lib.mapNullable apexOf (hostOf address);

      certNames = lib.unique (lib.filter (c: c != null) (map (v: v.acmeCert) vhosts));
      acmeHostNames = lib.unique (lib.filter (c: c != null) (map (v: v.useACMEHost) vhosts));

      package =
        if !cfg.extended then
          pkgs.caddy
        else if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then
          withSystem "x86_64-linux" ({ config, ... }: config.packages.caddy-extended-aarch64)
        else
          withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config.packages.caddy-extended);

      renderServer = address: lines: ''
        servers ${address} {
          protocols h1 h2
          ${lines}
        }
      '';
    in
    {
      options = {
        caddy = {
          enable = mkEnableOption "the Caddy reverse proxy" // {
            default = true;
          };

          extended = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to use the Caddy build with the layer4 and rate_limit plugins.";
          };

          listenAddresses = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Addresses virtual hosts bind to unless they set their own. Empty binds all interfaces.";
          };

          defaultPort = mkOption {
            type = types.port;
            default = 443;
            description = "HTTPS port for virtual hosts whose name carries no port or scheme.";
          };

          openFirewall = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to open TCP 80 and 443 on every interface.";
          };

          servers = mkOption {
            type = types.attrsOf types.lines;
            default = { };
            example = {
              "10.10.0.2:443" = "listener_wrappers { proxy_protocol { allow 10.10.0.1/32 } tls }";
            };
            description = "Per-listener server options. Keys must equal a site's bind address plus port.";
          };
        };

        services.caddy.virtualHosts = mkOption {
          type = types.attrsOf (
            types.submodule (
              { name, config, ... }:
              {
                options = {
                  acmeCert = mkOption {
                    type = types.nullOr types.str;
                    default = certOf name;
                    defaultText = lib.literalMD "the registrable domain of the virtual host name";
                    description = "security.acme certificate (apex plus wildcard) this virtual host serves.";
                  };

                  clientCA = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    description = "CA that client certificates must chain to. Requires a verified client certificate when set.";
                  };
                };

                config = {
                  hostName = mkDefault (
                    if lib.hasInfix ":" name || cfg.defaultPort == 443 then
                      name
                    else
                      "${name}:${toString cfg.defaultPort}"
                  );

                  listenAddresses = mkDefault cfg.listenAddresses;
                  useACMEHost = mkDefault (if config.clientCA == null then config.acmeCert else null);

                  # useACMEHost renders a bare `tls cert key`, which cannot carry client_auth.
                  extraConfig = mkIf (config.clientCA != null) (
                    lib.mkBefore ''
                      tls /var/lib/acme/${config.acmeCert}/cert.pem /var/lib/acme/${config.acmeCert}/key.pem {
                        client_auth {
                          mode require_and_verify
                          trust_pool file ${config.clientCA}
                        }
                      }
                    ''
                  );
                };
              }
            )
          );
        };
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = config.security.acme.defaults.dnsProvider != null;
            message = "caddy: derived certificates need a DNS-01 provider; enable acmeShared.";
          }
        ]
        ++ map (v: {
          assertion = hostOf v.hostName == null || v.acmeCert != null;
          message = "caddy: ${v.hostName} serves TLS without a certificate, so Caddy would issue its own.";
        }) vhosts
        ++ map (v: {
          assertion = lib.all (alias: certOf alias == v.acmeCert) v.serverAliases;
          message = "caddy: every alias of ${v.hostName} must fall under ${toString v.acmeCert}.";
        }) vhosts;

        services.caddy = {
          enable = true;
          inherit package;

          globalConfig = ''
            auto_https disable_redirects

            ${renderServer "" ""}
            ${lib.concatStrings (lib.mapAttrsToList renderServer cfg.servers)}
          '';

          extraConfig = ''
            (hsts) {
              header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
            }
          '';
        };

        # One apex plus wildcard per domain keeps service names out of CT logs.
        security.acme.certs = lib.genAttrs certNames (apex: {
          extraDomainNames = [ "*.${apex}" ];
          group = mkDefault config.services.caddy.group;
          reloadServices = mkIf (!lib.elem apex acmeHostNames) [ "caddy.service" ];
        });

        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
          80
          443
        ];
      };
    };
}
