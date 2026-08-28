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

      # nginx expands ${VAR}; keep the config's placeholders literal so the
      # substitutions below replace them rather than Nix interpolating them.
      apiPortPlaceholder = "\${LOCAL_API_PORT}";
      apiTokenPlaceholder = "\${LOCAL_API_TOKEN}";

      # The sidecar default-denies every route when LOCAL_API_TOKEN is unset
      # (local-api-server.mjs), and the token reaches it as a request header
      # nginx adds. nginx cannot expand an env var inside a directive, so the
      # whole proxy_set_header line arrives as an included snippet. systemd
      # stages it as a unit credential: root reads the 0400 sops file and
      # re-exposes it to the DynamicUser, which cannot open the original. The
      # credential directory path is fixed per unit, which is what makes an
      # include (no variables allowed) possible at all.
      localTokenConf = "/run/credentials/worldmonitor-nginx.service/local-token.conf";

      # The app's own nginx: docker/nginx.conf rendered to store paths. That is
      # the all-in-one image's config (root Dockerfile + docker/entrypoint.sh),
      # matching the shape this module deploys — sidecar and nginx side by side.
      # docker/nginx.conf.template belongs to the OTHER image (docker/Dockerfile,
      # frontend-only, proxying to a remote API); it sets no sidecar token, so
      # every /api route 503s under it.
      #
      # Serving this one verbatim keeps its SPA fallback, embed handling, asset
      # caching and inlined CSP intact instead of re-deriving them as NixOS
      # locations. Note it carries no /pro location — the paywall landing page
      # falls through to the dashboard, which is correct for a self-host.
      # Bound to loopback; the host reverse proxy terminates TLS/mTLS in front.
      nginxConf = pkgs.runCommand "worldmonitor-nginx.conf" { } ''
        substitute ${cfg.package.src}/docker/nginx.conf "$out" \
          --replace-fail '${apiPortPlaceholder}' '${toString cfg.sidecarPort}' \
          --replace-fail 'proxy_set_header X-WorldMonitor-Local-Token "${apiTokenPlaceholder}";' 'include ${localTokenConf};' \
          --replace-fail '/usr/share/nginx/html' '${appDir}/dist' \
          --replace-fail '/etc/nginx/mime.types' '${pkgs.nginx}/conf/mime.types' \
          --replace-fail 'listen 8080;' 'listen 127.0.0.1:${toString cfg.port};' \
          --replace-fail 'access_log /dev/stdout main;' 'access_log off;' \
          --replace-fail 'error_log /dev/stderr warn;' 'error_log stderr warn;'

        # error_log takes the bare name `stderr`, not the /dev path: under
        # systemd that path is a journal socket, and nginx open()s it as a file
        # (ENXIO). The directive in the file also outranks the unit's -e, so
        # rewriting it here is the only place that takes effect.
        #
        # The entrypoint generates this from WM_TRUSTED_PROXY_CIDRS; nothing
        # generates it here, and a missing include is a hard parse error. The
        # host reverse proxy is the only client, so real-IP rewriting would
        # only ever substitute one loopback address for another.
        substituteInPlace "$out" \
          --replace-fail 'include       /tmp/nginx-realip.conf;' ""

        # -g pid: the runtime unit passes its own, and a `pid` directive in the
        # file would collide with it. Temp paths go relative so nginx resolves
        # them against its prefix (-p): /run/worldmonitor-nginx at runtime,
        # $TMPDIR during the build-time -t below. The upstream absolutes assume
        # the container's writable /tmp. nginx creates the subdirs itself.
        substituteInPlace "$out" \
          --replace-fail 'pid /tmp/nginx.pid;' "" \
          --replace-fail 'client_body_temp_path /tmp/nginx-client-body;' 'client_body_temp_path body;' \
          --replace-fail 'proxy_temp_path /tmp/nginx-proxy;' 'proxy_temp_path proxy;' \
          --replace-fail 'fastcgi_temp_path /tmp/nginx-fastcgi;' 'fastcgi_temp_path fastcgi;' \
          --replace-fail 'uwsgi_temp_path /tmp/nginx-uwsgi;' 'uwsgi_temp_path uwsgi;' \
          --replace-fail 'scgi_temp_path /tmp/nginx-scgi;' 'scgi_temp_path scgi;'

        # The credential does not exist at build time and a missing include
        # aborts the parse, so -t runs against a copy carrying a stand-in.
        sed 's|include ${localTokenConf};|proxy_set_header X-WorldMonitor-Local-Token "check";|' \
          "$out" > "$TMPDIR/check.conf"
        ${lib.getExe pkgs.nginx} -t -c "$TMPDIR/check.conf" -p "$TMPDIR" -e stderr -g "pid $TMPDIR/nginx.pid;"
      '';

      # Env files that carry secrets are rendered by sops; non-secret env is set
      # inline on each unit. UPSTASH_ALLOW_INSECURE_HTTP is required because the
      # REST proxy is plain HTTP on loopback.
      redisConn = "redis://:${
        config.sops.placeholder."worldmonitor/redis-password"
      }@127.0.0.1:${toString cfg.redisPort}";

      # Shared by both seeder units.
      #
      # API_BASE_URL is where seeders reach the app's own HTTP API for the
      # handful of round-trips Redis cannot serve (seed-insights warms the news
      # digest through it; seed-resilience-scores reads rankings). Upstream
      # defaults it to https://api.worldmonitor.app, which a self-host has no
      # credentials for. Points at the local nginx, not the sidecar directly,
      # because nginx is what attaches the sidecar's X-WorldMonitor-Local-Token.
      # Listed before EnvironmentFile, so a value in extraEnvironmentFiles still
      # wins if one is set there.
      seedEnvironment = {
        UPSTASH_REDIS_REST_URL = "http://127.0.0.1:${toString cfg.redisRestPort}";
        UPSTASH_ALLOW_INSECURE_HTTP = "true";
        API_BASE_URL = "http://127.0.0.1:${toString cfg.port}";
      };
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

        insightsInterval = mkOption {
          type = types.nullOr types.str;
          default = "30min";
          example = "1h";
          description = ''
            How often to re-run the insights seeder on its own, as a systemd
            time span. The AI Insights panel treats a world brief older than
            60 minutes as missing and shows an UNAVAILABLE badge, so the
            once-per-boot batch in {option}`worldmonitor.seedOnBoot` leaves the
            panel unavailable for all but the first hour of any uptime.
            Upstream runs this seeder on a 30-minute cron.

            Invokes the seeder directly rather than through run-seeders.sh, so
            its own diagnostics reach the journal instead of being reduced to
            one summary line. Null disables the timer.
          '';
        };
      };

      config = mkIf cfg.enable {
        # Five secrets with no safe defaults, mirroring the compose stack. Their
        # encrypted values live in the nix-secrets repo.
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

            # restartUnits on both halves of the local API token. A template's
            # rendered content changing does not change the unit definition, so
            # a `switch` otherwise leaves the running processes holding the old
            # value: the sidecar keeps default-denying and nginx keeps sending a
            # header that no longer matches.
            "worldmonitor-sidecar.env" = {
              restartUnits = [ "worldmonitor-sidecar.service" ];
              content = ''
                UPSTASH_REDIS_REST_TOKEN=${config.sops.placeholder."worldmonitor/redis-token"}
                WM_SESSION_SECRET=${config.sops.placeholder."worldmonitor/session-secret"}
                RELAY_SHARED_SECRET=${config.sops.placeholder."worldmonitor/relay-secret"}
                LOCAL_API_TOKEN=${config.sops.placeholder."worldmonitor/local-api-token"}
              '';
            };

            # The other half: nginx sends this on every /api request and the
            # sidecar compares it against LOCAL_API_TOKEN above. A whole
            # directive rather than a bare value because nginx cannot
            # interpolate one into a config.
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
              # Staged for the DynamicUser, which cannot read the 0400 original.
              # The name fixes the path the rendered config includes.
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

            environment = seedEnvironment;

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
        }
        // lib.optionalAttrs (cfg.insightsInterval != null) {
          # seed-insights on its own cadence. The batch above takes 30+ minutes
          # end to end, so raising its frequency to match the brief's 60-minute
          # freshness window would mean overlapping runs; this reruns the one
          # seeder the AI Insights badge depends on.
          #
          # No run-seeders.sh wrapper: it captures each seeder's output to a
          # temp file and reports a single classified line, which hides the
          # `FETCH FAILED: ...` that precedes a graceful failure. Straight to
          # the journal instead. The seeder takes its own Redis lock, so a run
          # overlapping the batch skips itself rather than racing it.
          worldmonitor-seed-insights = {
            description = "World Monitor insights seed";
            after = [ "worldmonitor-redis-rest.service" ];
            requires = [ "worldmonitor-redis-rest.service" ];

            environment = seedEnvironment;

            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${lib.getExe pkgs.nodejs_24} ${cfg.relayPackage}/share/worldmonitor-relay/scripts/seed-insights.mjs";
              EnvironmentFile = [
                config.sops.templates."worldmonitor-relay.env".path
              ]
              ++ cfg.extraEnvironmentFiles;
              WorkingDirectory = "/var/lib/worldmonitor-seed-insights";
              StateDirectory = "worldmonitor-seed-insights";
              DynamicUser = true;
              # A graceful fetch failure is a distinct nonzero exit, not a
              # crash; the seeder preserves the previous keys and the next tick
              # retries. Failing the unit on it would only add journal noise.
              SuccessExitStatus = [
                "0"
                "75"
              ];
            };
          };
        };

        # Fire the seed off the activation path. On a reboot it runs OnBootSec
        # later; on a `switch` (boot already elapsed) it fires right away, but
        # asynchronously via the timer rather than inside the switch transaction,
        # so activation returns immediately instead of waiting out the seeders.
        systemd.timers =
          lib.optionalAttrs cfg.seedOnBoot {
            worldmonitor-seed = {
              description = "World Monitor initial Redis seed trigger";
              wantedBy = [ "timers.target" ];
              timerConfig.OnBootSec = "1min";
            };
          }
          // lib.optionalAttrs (cfg.insightsInterval != null) {
            worldmonitor-seed-insights = {
              description = "World Monitor insights seed trigger";
              wantedBy = [ "timers.target" ];
              timerConfig = {
                # First tick after the boot batch has had time to lay down the
                # news digest this seeder reads; from then on, on its own period.
                OnBootSec = "10min";
                OnUnitActiveSec = cfg.insightsInterval;
                # The brief is only ever as fresh as the last tick, so a run
                # missed across a suspend should catch up rather than wait out a
                # full period with the badge stuck on UNAVAILABLE.
                Persistent = true;
              };
            };
          };
      };
    };
}
