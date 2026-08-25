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

      # nginx expands ${VAR}; keep the template's placeholder literal so the
      # substitute below can replace it rather than Nix interpolating it.
      apiPlaceholder = "\${API_UPSTREAM}";

      # The app's own nginx: docker/nginx.conf.template rendered to store paths.
      # Serving it verbatim keeps its SPA fallback, /pro handling, asset caching
      # and (large) CSP intact instead of re-deriving them as NixOS locations.
      # Bound to loopback; the host reverse proxy terminates TLS/mTLS in front.
      nginxConf = pkgs.runCommand "worldmonitor-nginx.conf" { } ''
        substitute ${cfg.package.src}/docker/nginx.conf.template "$out" \
          --replace-fail '${apiPlaceholder}' 'http://127.0.0.1:${toString cfg.sidecarPort}' \
          --replace-fail '/usr/share/nginx/html' '${appDir}/dist' \
          --replace-fail '/etc/nginx/mime.types' '${pkgs.nginx}/conf/mime.types' \
          --replace-fail '/etc/nginx/security_headers.conf' '${appDir}/nginx/security_headers.conf' \
          --replace-fail '/etc/nginx/embed_security_headers.conf' '${appDir}/nginx/embed_security_headers.conf' \
          --replace-fail 'listen 80;' 'listen 127.0.0.1:${toString cfg.port};'

        # Temp paths kept relative so nginx resolves them against its prefix
        # (-p): /run/worldmonitor-nginx at runtime, $TMPDIR during the build-time
        # -t. The template declares none, so nginx would otherwise use the
        # compiled-in absolute defaults it cannot create as a non-root unit; an
        # absolute /run/... path would instead fail `nginx -t` here, where /run
        # does not exist. nginx creates these subdirs under the prefix itself.
        substituteInPlace "$out" --replace-fail 'http {' 'http {
          client_body_temp_path body;
          proxy_temp_path       proxy;
          fastcgi_temp_path     fastcgi;
          uwsgi_temp_path       uwsgi;
          scgi_temp_path        scgi;
          access_log            off;'

        # -g pid: the template sets no pid, so `nginx -t` would open its
        # compiled-in default (/var/log/nginx/nginx.pid), unwritable here. The
        # runtime unit passes the same override.
        ${lib.getExe pkgs.nginx} -t -c "$out" -p "$TMPDIR" -e stderr -g "pid $TMPDIR/nginx.pid;"
      '';

      # Env files that carry secrets are rendered by sops; non-secret env is set
      # inline on each unit. UPSTASH_ALLOW_INSECURE_HTTP is required because the
      # REST proxy is plain HTTP on loopback.
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
        # Four secrets with no safe defaults, mirroring the compose stack. Their
        # encrypted values live in the nix-secrets repo.
        sops = {
          secrets = {
            "worldmonitor/redis-token" = { };
            "worldmonitor/redis-password" = { };
            "worldmonitor/session-secret" = { };
            "worldmonitor/relay-secret" = { };
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

            "worldmonitor-sidecar.env".content = ''
              UPSTASH_REDIS_REST_TOKEN=${config.sops.placeholder."worldmonitor/redis-token"}
              WM_SESSION_SECRET=${config.sops.placeholder."worldmonitor/session-secret"}
              RELAY_SHARED_SECRET=${config.sops.placeholder."worldmonitor/relay-secret"}
            '';
          };
        };

        # Dedicated Redis cache: password-gated and memory-bounded like the
        # compose `redis` service.
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
              DynamicUser = true;
              Restart = "on-failure";
              RestartSec = 5;
            };
          };
        }
        // lib.optionalAttrs cfg.seedOnBoot {
          # Upstream's host-side seeder batch, run verbatim from the relay
          # package: it ships every seed-*.mjs plus scripts/node_modules and
          # already handles per-seeder timeouts, bundle exemptions, and
          # skip/fail classification, always exiting success. Reuses the relay
          # env for UPSTASH_REDIS_REST_TOKEN.
          worldmonitor-seed = {
            description = "World Monitor initial Redis seed";
            # null seeder batch runs 30+ min, so it would block
            # multi-user.target and hang `nixos-rebuild switch` for its whole
            # duration.
            after = [ "worldmonitor-redis-rest.service" ];
            requires = [ "worldmonitor-redis-rest.service" ];

            # node + timeout/basename/mktemp/tail (coreutils) + grep/sed for the
            # override-file parse in run-seeders.sh; curl for the readiness wait.
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
              # Wait for the REST proxy to answer (any status, incl. 401 = up)
              # before firing seeders that would otherwise all fail-fast.
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

        # Fire the seed off the activation path. On a reboot it runs OnBootSec
        # later; on a `switch` (boot already elapsed) it fires right away, but
        # asynchronously via the timer rather than inside the switch transaction,
        # so activation returns immediately instead of waiting out the seeders.
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
