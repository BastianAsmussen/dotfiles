{
  flake.nixosModules.nix-serve =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkOption mkIf types;

      cfg = config.nix-serve-extras;
    in
    {
      options.nix-serve-extras = {
        exposePublicly = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether to expose the binary cache through an nginx reverse proxy
            with ACME TLS on cache.asmussen.tech.
          '';
        };

        bindAddress = mkOption {
          type = types.str;
          default = "localhost";
          description = ''
            Address nix-serve listens on.  Override to the host's WireGuard IP
            on peers whose cache must be reachable from remote machines over the
            WireGuard tunnel.
          '';
        };
      };

      config =
        let
          hostname = config.networking.hostName;
          cacheKeySecret = "hosts/${hostname}/cache-private-key";

          serveCfg = config.services.nix-serve;

          allowlistDir = "/run/nix-cache-allowlist";
          allowlistFile = "${allowlistDir}/allowed.map";
        in
        {
          sops.secrets.${cacheKeySecret} = { };

          services.nix-serve = {
            inherit (cfg) bindAddress;

            enable = true;
            package = pkgs.haskell.lib.addPkgconfigDepend pkgs.nix-serve-ng pkgs.libcpuid;
            secretKeyFile = config.sops.secrets.${cacheKeySecret}.path;
          };

          nix.settings.secret-key-files = [ config.sops.secrets.${cacheKeySecret}.path ];

          # Only paths something built are served: sources, sops copies and .drv files have no deriver.
          systemd = {
            tmpfiles.rules = [
              "d ${allowlistDir} 0755 root root -"
              "f ${allowlistFile} 0644 root root -"
            ];

            services.nix-cache-allowlist = {
              description = "Allowlist built store paths for the binary cache";
              after = [ "nix-daemon.socket" ];
              path = [
                config.nix.package
                pkgs.jq
                pkgs.diffutils
              ];

              serviceConfig.Type = "oneshot";
              script = ''
                tmp="${allowlistFile}.tmp"
                nix path-info --all --json --json-format 1 \
                  | jq -r 'to_entries[] | select(.value.deriver != null) | "\(.key[11:43]) 1;"' > "$tmp"

                if cmp -s "$tmp" "${allowlistFile}"; then
                  rm "$tmp"
                else
                  mv "$tmp" "${allowlistFile}"
                  if systemctl is-active -q nginx; then
                    systemctl reload nginx
                  fi
                fi
              '';
            };

            timers.nix-cache-allowlist = {
              description = "Periodic binary cache allowlist refresh";
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnBootSec = "1min";
                OnUnitActiveSec = "10min";
              };
            };
          };

          services.nginx = {
            mapHashMaxSize = 262144;
            mapHashBucketSize = 128;

            # Keyed on the raw request line, which is what proxy_pass forwards.
            appendHttpConfig = ''
              map $request_uri $nix_cache_hash {
                "~^/(?<h>[0-9a-z]{32})\.narinfo$" $h;
                "~^/nar/(?<h>[0-9a-z]{32})(?:-[0-9a-z]{52})?\.nar$" $h;
                default "";
              }

              map $nix_cache_hash $nix_cache_allowed {
                include ${allowlistFile};
                default 0;
              }
            '';

            # Unconditional so hand-written cache vhosts are gated too.
            virtualHosts."cache.asmussen.tech".locations = {
              "/".extraConfig = ''
                if ($nix_cache_allowed = 0) {
                  return 404;
                }
              '';

              "= /nix-cache-info".proxyPass = "http://${serveCfg.bindAddress}:${toString serveCfg.port}";
            };
          };

          # Expose the cache behind nginx with HTTPS only when requested.
          nginx.reverseProxies.nix-cache = mkIf cfg.exposePublicly {
            enable = true;
            domain = "cache.asmussen.tech";
            location = "/";
            upstream = "http://${serveCfg.bindAddress}:${toString serveCfg.port}";
            ssl = {
              dnsProvider = "cloudflare";
              environmentFile = config.sops.templates."cloudflare-acme-env".path;
            };
          };
        };
    };
}
