{
  flake.nixosModules.worldmonitor =
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

      cfg = config.worldmonitor;

      appDir = "${cfg.package}/share/worldmonitor";

      # Keep nginx placeholders literal for substitution instead of Nix
      # interpolation.
      apiPortPlaceholder = "\${LOCAL_API_PORT}";
      apiTokenPlaceholder = "\${LOCAL_API_TOKEN}";

      # Pass the sidecar token through a fixed-path unit credential and nginx
      # include.
      localTokenConf = "/run/credentials/worldmonitor-nginx.service/local-token.conf";

      # Use the all-in-one nginx config with sidecar auth and SPA fallback.
      nginxConf = pkgs.runCommand "worldmonitor-nginx.conf" { } ''
        substitute ${cfg.package.src}/docker/nginx.conf "$out" \
          --replace-fail '${apiPortPlaceholder}' '${toString cfg.sidecarPort}' \
          --replace-fail 'proxy_set_header X-WorldMonitor-Local-Token "${apiTokenPlaceholder}";' 'include ${localTokenConf};' \
          --replace-fail '/usr/share/nginx/html' '${appDir}/dist' \
          --replace-fail '/etc/nginx/mime.types' '${pkgs.nginx}/conf/mime.types' \
          --replace-fail 'listen 8080;' 'listen 127.0.0.1:${toString cfg.port};' \
          --replace-fail 'access_log /dev/stdout main;' 'access_log off;' \
          --replace-fail 'error_log /dev/stderr warn;' 'error_log stderr warn;'

        # nginx must log to `stderr`; omit the absent real-IP include.
        substituteInPlace "$out" \
          --replace-fail 'include       /tmp/nginx-realip.conf;' ""

        # Use prefix-relative temp paths and let the unit supply the pid path.
        substituteInPlace "$out" \
          --replace-fail 'pid /tmp/nginx.pid;' "" \
          --replace-fail 'client_body_temp_path /tmp/nginx-client-body;' 'client_body_temp_path body;' \
          --replace-fail 'proxy_temp_path /tmp/nginx-proxy;' 'proxy_temp_path proxy;' \
          --replace-fail 'fastcgi_temp_path /tmp/nginx-fastcgi;' 'fastcgi_temp_path fastcgi;' \
          --replace-fail 'uwsgi_temp_path /tmp/nginx-uwsgi;' 'uwsgi_temp_path uwsgi;' \
          --replace-fail 'scgi_temp_path /tmp/nginx-scgi;' 'scgi_temp_path scgi;'

        # Test with a stand-in token include; the real credential is
        # runtime-only.
        sed 's|include ${localTokenConf};|proxy_set_header X-WorldMonitor-Local-Token "check";|' \
          "$out" > "$TMPDIR/check.conf"
        ${lib.getExe pkgs.nginx} -t -c "$TMPDIR/check.conf" -p "$TMPDIR" -e stderr -g "pid $TMPDIR/nginx.pid;"
      '';

      # Allow plain HTTP only for the loopback REST proxy.
      redisConn = "redis://:${
        config.sops.placeholder."worldmonitor/redis-password"
      }@127.0.0.1:${toString cfg.redisPort}";
    in
    {
      options.worldmonitor = {
        enable = mkEnableOption "the World Monitor dashboard (app, API sidecar, AIS relay, Redis + REST proxy), built from source";

        package = mkOption {
          type = types.package;
          default = pkgs.worldmonitor;
          defaultText = lib.literalExpression "pkgs.worldmonitor";
          description = "The World Monitor app package (static SPA plus the Node API sidecar).";
        };

        relayPackage = mkOption {
          type = types.package;
          default = pkgs.worldmonitor-relay;
          defaultText = lib.literalExpression "pkgs.worldmonitor-relay";
          description = "The AIS relay sidecar package.";
        };

        redisRestPackage = mkOption {
          type = types.package;
          default = pkgs.worldmonitor-redis-rest;
          defaultText = lib.literalExpression "pkgs.worldmonitor-redis-rest";
          description = "The Upstash-compatible Redis REST proxy package.";
        };

        trustedHost = mkOption {
          type = types.str;
          default = "worldmonitor.asmussen.tech";
          description = ''
            Public authority the dashboard is served on. The host reverse proxy
            forwards this Host to the app nginx; declare the matching
            nginx.reverseProxies entry there.
          '';
        };

        port = mkOption {
          type = types.port;
          default = 8080;
          description = "Loopback port the app's own nginx binds; the host reverse proxy's upstream.";
        };

        sidecarPort = mkOption {
          type = types.port;
          default = 46123;
          description = "Loopback port the Node API sidecar binds (nginx proxies /api to it).";
        };

        relayPort = mkOption {
          type = types.port;
          default = 3004;
          description = "Loopback port the AIS relay binds.";
        };

        redisRestPort = mkOption {
          type = types.port;
          default = 8079;
          description = "Loopback port the Redis REST proxy binds.";
        };

        redisPort = mkOption {
          type = types.port;
          default = 6390;
          description = "Loopback TCP port for the dedicated Redis instance (kept off 6379 to avoid clashing with other local Redis servers).";
        };

        extraEnvironmentFiles = mkOption {
          type = types.listOf types.path;
          default = [ ];
          example = lib.literalExpression ''[ config.sops.secrets."worldmonitor/api-keys".path ]'';
          description = ''
            Extra systemd EnvironmentFiles layered onto the app, relay and
            seeder units, for the optional upstream API keys (GROQ_API_KEY,
            FINNHUB_API_KEY, AISSTREAM_API_KEY, ...). Features degrade
            gracefully without them.
          '';
        };

        seedOnBoot = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Run the upstream seeders once on boot to pre-fill Redis (earthquakes,
            markets, disasters, ...) so the first dashboard load is populated
            rather than filling in gradually as the relay's refresh intervals
            fire. Redis is an unpersisted LRU cache, so it starts empty every
            boot and this reseeds it each time. Seeders that need an absent API
            key self-skip; the run always exits success.
          '';
        };
      };

      config = mkIf cfg.enable {
        # Declare the compose stack's secrets from nix-secrets.
        sops = {
          secrets = {
            "worldmonitor/redis-token" = { };
            "worldmonitor/redis-password" = { };
            "worldmonitor/session-secret" = { };
            "worldmonitor/relay-secret" = { };
            "worldmonitor/local-api-token" = { };
          };

          templates = {
            "worldmonitor-redis-rest.env".content = ''
              SRH_TOKEN=${config.sops.placeholder."worldmonitor/redis-token"}
              SRH_CONNECTION_STRING=${redisConn}
            '';

            "worldmonitor-relay.env".content = ''
              RELAY_SHARED_SECRET=${config.sops.placeholder."worldmonitor/relay-secret"}
              UPSTASH_REDIS_REST_TOKEN=${config.sops.placeholder."worldmonitor/redis-token"}
            '';

            # Restart both token consumers when rendered secrets change.
            "worldmonitor-sidecar.env" = {
              restartUnits = [ "worldmonitor-sidecar.service" ];
              content = ''
                UPSTASH_REDIS_REST_TOKEN=${config.sops.placeholder."worldmonitor/redis-token"}
                WM_SESSION_SECRET=${config.sops.placeholder."worldmonitor/session-secret"}
                RELAY_SHARED_SECRET=${config.sops.placeholder."worldmonitor/relay-secret"}
                LOCAL_API_TOKEN=${config.sops.placeholder."worldmonitor/local-api-token"}
              '';
            };

            # Send the same local token from nginx to the sidecar.
            "worldmonitor-nginx-local-token.conf" = {
              restartUnits = [ "worldmonitor-nginx.service" ];
              content = ''
                proxy_set_header X-WorldMonitor-Local-Token "${
                  config.sops.placeholder."worldmonitor/local-api-token"
                }";
              '';
            };
          };
        };

        # Provide a password-gated, memory-bounded Redis cache.
        services.redis.servers.worldmonitor = {
          enable = true;
          bind = "127.0.0.1";
          port = cfg.redisPort;
          requirePassFile = config.sops.secrets."worldmonitor/redis-password".path;
          settings = {
            maxmemory = "256mb";
            maxmemory-policy = "allkeys-lru";
          };
        };

        systemd.services = {
          worldmonitor-redis-rest = {
            description = "World Monitor Redis REST proxy";
            wantedBy = [ "multi-user.target" ];
            after = [ "redis-worldmonitor.service" ];
            requires = [ "redis-worldmonitor.service" ];
            environment.PORT = toString cfg.redisRestPort;
            serviceConfig = {
              ExecStart = lib.getExe cfg.redisRestPackage;
              EnvironmentFile = config.sops.templates."worldmonitor-redis-rest.env".path;
              DynamicUser = true;
              Restart = "on-failure";
              RestartSec = 5;
            };
          };

          worldmonitor-relay = {
            description = "World Monitor AIS relay";
            wantedBy = [ "multi-user.target" ];
            after = [ "worldmonitor-redis-rest.service" ];
            requires = [ "worldmonitor-redis-rest.service" ];
            environment = {
              PORT = toString cfg.relayPort;
              UPSTASH_REDIS_REST_URL = "http://127.0.0.1:${toString cfg.redisRestPort}";
              UPSTASH_ALLOW_INSECURE_HTTP = "true";
            };

            serviceConfig = {
              ExecStart = lib.getExe cfg.relayPackage;
              EnvironmentFile = [
                config.sops.templates."worldmonitor-relay.env".path
              ]
              ++ cfg.extraEnvironmentFiles;
              WorkingDirectory = "/var/lib/worldmonitor-relay";
              StateDirectory = "worldmonitor-relay";
              DynamicUser = true;
              Restart = "on-failure";
              RestartSec = 5;
            };
          };

          worldmonitor-sidecar = {
            description = "World Monitor API sidecar";
            wantedBy = [ "multi-user.target" ];
            after = [ "worldmonitor-redis-rest.service" ];
            requires = [ "worldmonitor-redis-rest.service" ];
            environment = {
              LOCAL_API_PORT = toString cfg.sidecarPort;
              LOCAL_API_MODE = "docker";
              LOCAL_API_CLOUD_FALLBACK = "false";
              WM_TRUSTED_PROXY_CIDRS = "127.0.0.1/32,::1/128";
              UPSTASH_REDIS_REST_URL = "http://127.0.0.1:${toString cfg.redisRestPort}";
              WS_RELAY_URL = "http://127.0.0.1:${toString cfg.relayPort}";
            };

            serviceConfig = {
              ExecStart = lib.getExe cfg.package;
              EnvironmentFile = [
                config.sops.templates."worldmonitor-sidecar.env".path
              ]
              ++ cfg.extraEnvironmentFiles;
              DynamicUser = true;
              Restart = "on-failure";
              RestartSec = 5;
            };
          };

          worldmonitor-nginx = {
            description = "World Monitor app nginx (SPA + /api)";
            wantedBy = [ "multi-user.target" ];
            after = [ "worldmonitor-sidecar.service" ];
            wants = [ "worldmonitor-sidecar.service" ];
            serviceConfig = {
              ExecStart = "${lib.getExe pkgs.nginx} -c ${nginxConf} -p /run/worldmonitor-nginx -e stderr -g 'daemon off; pid /run/worldmonitor-nginx/nginx.pid;'";
              ExecReload = "${lib.getExe pkgs.nginx} -c ${nginxConf} -p /run/worldmonitor-nginx -s reload";
              RuntimeDirectory = "worldmonitor-nginx";
              # Stage the root-only token for nginx's DynamicUser.
              LoadCredential = "local-token.conf:${
                config.sops.templates."worldmonitor-nginx-local-token.conf".path
              }";

              DynamicUser = true;
              Restart = "on-failure";
              RestartSec = 5;
            };
          };
        }
        // lib.optionalAttrs cfg.seedOnBoot {
          # Run upstream's seeder batch with the relay environment.
          worldmonitor-seed = {
            description = "World Monitor initial Redis seed";
            # Do not block activation on the 30+ minute seed batch.
            after = [ "worldmonitor-redis-rest.service" ];
            requires = [ "worldmonitor-redis-rest.service" ];

            path = with pkgs; [
              nodejs_24
              coreutils
              gnugrep
              gnused
              curl
            ];

            environment = {
              UPSTASH_REDIS_REST_URL = "http://127.0.0.1:${toString cfg.redisRestPort}";
              UPSTASH_ALLOW_INSECURE_HTTP = "true";
            };

            serviceConfig = {
              # Stop the ~30-min seeder batch from running during activation.
              Type = "exec";
              # Wait for the REST proxy before starting seeders.
              ExecStartPre = "${lib.getExe pkgs.curl} -s -o /dev/null --retry 30 --retry-connrefused --retry-delay 1 http://127.0.0.1:${toString cfg.redisRestPort}/";
              ExecStart = "${lib.getExe pkgs.bash} ${cfg.relayPackage}/share/worldmonitor-relay/scripts/run-seeders.sh";
              EnvironmentFile = [
                config.sops.templates."worldmonitor-relay.env".path
              ]
              ++ cfg.extraEnvironmentFiles;
              WorkingDirectory = "/var/lib/worldmonitor-seed";
              StateDirectory = "worldmonitor-seed";
              DynamicUser = true;
            };
          };
        };

        # Use timers to keep the lengthy seed batch off the activation path.
        systemd.timers = lib.optionalAttrs cfg.seedOnBoot {
          worldmonitor-seed = {
            description = "World Monitor initial Redis seed trigger";
            wantedBy = [ "timers.target" ];
            timerConfig.OnBootSec = "1min";
          };
        };
      };
    };
}
