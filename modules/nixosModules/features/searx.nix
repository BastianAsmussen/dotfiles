{
  flake.nixosModules.searx =
    {
      config,
      lib,
      pkgs,
      options,
      ...
    }:
    let
      inherit (lib)
        mkEnableOption
        mkOption
        mkIf
        types
        ;

      cfg = config.searx;
    in
    {
      options.searx = {
        enable = mkEnableOption "the SearxNG search engine";

        domain = mkOption {
          type = types.str;
          default = "search.asmussen.tech";
          description = "The domain under which SearxNG will be served.";
        };
      };

      config = mkIf cfg.enable (
        lib.mkMerge [
          {
            services.searx = {
              enable = true;
              package = pkgs.searxng;
              redisCreateLocally = true;
              configureUwsgi = true;
              uwsgiConfig.http = "127.0.0.1:8888";

              environmentFile = config.sops.templates."searx-env".path;
              settings = {
                use_default_settings = true;
                general = {
                  instance_name = "SearXNG";
                  debug = false;
                  enable_metrics = false;
                };

                search = {
                  safe_search = 2;
                  autocomplete_min = 2;
                  autocomplete = "duckduckgo";
                  ban_time_on_fail = 5;
                  max_ban_time_on_fail = 120;
                };

                server = {
                  base_url = "https://${cfg.domain}";
                  bind_address = "::1";
                  secret_key = "$SEARX_SECRET";
                  limiter = true;
                  public_instance = false;
                  image_proxy = true;
                  method = "GET";
                };

                outgoing = {
                  request_timeout = 5.0;
                  max_request_timeout = 15.0;
                  pool_connections = 100;
                  pool_maxsize = 15;
                  enable_http2 = true;
                };

                ui = {
                  static_use_hash = true;
                  default_locale = "en";
                  query_in_title = true;
                  infinite_scroll = false;
                  center_alignment = true;
                  default_theme = "simple";
                  search_on_category_select = false;
                  hotkeys = "vim";
                };

                enabled_plugins = [
                  "Basic Calculator"
                  "Hash plugin"
                  "Tor check plugin"
                  "Open Access DOI rewrite"
                  "Hostnames plugin"
                  "Unit converter plugin"
                  "Tracker URL remover"
                ];
              };

              limiterSettings = {
                real_ip = {
                  x_for = 1;
                  ipv4_prefix = 32;
                  ipv6_prefix = 56;
                };

                botdetection = {
                  ip_limit = {
                    filter_link_local = true;
                    link_token = true;
                  };
                };
              };
            };

            sops.templates."searx-env".content = ''
              SEARX_SECRET=${config.sops.placeholder."services/searx/secret-key"}
            '';

            nginx.reverseProxies.searx = {
              inherit (cfg) domain;

              enable = true;
              location = "/";
              upstream = "http://localhost:8888";
              ssl = {
                dnsProvider = "cloudflare";
                environmentFile = config.sops.templates."cloudflare-acme-env".path;
              };
            };
          }

          (lib.optionalAttrs (options ? persistence) {
            persistence.directories = [
              {
                directory = "/var/cache/searx";
                user = "searx";
                group = "searx";
              }
            ];
          })
        ]
      );
    };
}
