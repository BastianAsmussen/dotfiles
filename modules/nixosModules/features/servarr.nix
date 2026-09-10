{
  flake.nixosModules.servarr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        mkOption
        types
        getExe
        ;

      cfg = config.servarr;

      prowlarrUrl = "http://localhost:${toString config.services.prowlarr.settings.server.port}";

      # The acquisition-only root for anime movies, and the tag that marks
      # them. Spelled once: both the tmpfiles rule and the reconciler below
      # need to agree on it.
      animeRoot = "/srv/media/radarr/anime";
      animeTag = "anime";

      curl = getExe pkgs.curl;
      jq = getExe pkgs.jq;
      sed = lib.getExe pkgs.gnused;

      # Prowlarr keeps indexers in its own SQLite DB, so the only way to make
      # any of this declarative is to reconcile it through the API on
      # activation, the way qbittorrent-sync-categories does for categories.
      syncScript = pkgs.writeShellScript "prowlarr-sync-indexers" ''
        set -euo pipefail

        key="$(${sed} -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p' /var/lib/prowlarr/config.xml)"
        if [ -z "$key" ]; then
          echo "Could not read Prowlarr's API key." >&2
          exit 1
        fi

        api() {
          ${curl} -sS --fail-with-body -H "X-Api-Key: $key" "$@"
        }

        for attempt in $(seq 60); do
          status="$(${curl} -sS -o /dev/null -w '%{http_code}' -H "X-Api-Key: $key" \
            "${prowlarrUrl}/api/v1/health" 2>/dev/null || true)"
          [ "$status" = "200" ] && break

          if [ "$attempt" -eq 60 ]; then
            echo "Prowlarr API never became ready at ${prowlarrUrl} (last HTTP $status)!" >&2
            exit 1
          fi

          sleep 1
        done

        # The tag is what binds an indexer to the proxy; Prowlarr applies a
        # proxy only to indexers sharing one of its tags.
        tag_id="$(api "${prowlarrUrl}/api/v1/tag" \
          | ${jq} -r --arg l ${lib.escapeShellArg cfg.prowlarr.flaresolverrTag} \
              'map(select(.label == $l)) | first | .id // empty')"

        if [ -z "$tag_id" ]; then
          tag_id="$(api -X POST -H 'Content-Type: application/json' \
            -d "$(${jq} -nc --arg l ${lib.escapeShellArg cfg.prowlarr.flaresolverrTag} '{label: $l}')" \
            "${prowlarrUrl}/api/v1/tag" | ${jq} -r .id)"
          echo "Created Prowlarr tag: ${cfg.prowlarr.flaresolverrTag} (id $tag_id)"
        fi

        proxy_id="$(api "${prowlarrUrl}/api/v1/indexerproxy" \
          | ${jq} -r 'map(select(.implementation == "FlareSolverr")) | first | .id // empty')"

        proxy_body="$(${jq} -nc \
          --arg host ${lib.escapeShellArg cfg.prowlarr.flaresolverrUrl} \
          --argjson tag "$tag_id" '{
            name: "FlareSolverr",
            implementation: "FlareSolverr",
            implementationName: "FlareSolverr",
            configContract: "FlareSolverrSettings",
            tags: [$tag],
            fields: [
              { name: "host", value: $host },
              { name: "requestTimeout", value: 60 }
            ]
          }')"

        if [ -z "$proxy_id" ]; then
          api -X POST -H 'Content-Type: application/json' -d "$proxy_body" \
            "${prowlarrUrl}/api/v1/indexerproxy" > /dev/null
          echo "Created the FlareSolverr indexer proxy."
        else
          # Only ever add the tag: the proxy may carry others set by hand.
          current="$(api "${prowlarrUrl}/api/v1/indexerproxy/$proxy_id")"

          if ! echo "$current" | ${jq} -e --argjson t "$tag_id" '.tags | index($t)' > /dev/null; then
            echo "$current" | ${jq} -c --argjson t "$tag_id" '.tags += [$t]' \
              | api -X PUT -H 'Content-Type: application/json' -d @- \
                  "${prowlarrUrl}/api/v1/indexerproxy/$proxy_id" > /dev/null
            echo "Tagged the FlareSolverr proxy with ${cfg.prowlarr.flaresolverrTag}."
          fi
        fi

        indexers="$(api "${prowlarrUrl}/api/v1/indexer")"

        reconcile() {
          local name="$1"
          local filter="$2"
          local label="$3"
          local id current updated

          id="$(echo "$indexers" | ${jq} -r --arg n "$name" \
            'map(select(.name == $n)) | first | .id // empty')"

          if [ -z "$id" ]; then
            echo "Prowlarr has no indexer named '$name'; skipping." >&2
            return 0
          fi

          current="$(api "${prowlarrUrl}/api/v1/indexer/$id")"
          updated="$(echo "$current" | ${jq} -c --argjson t "$tag_id" "$filter")"

          if [ "$(echo "$current" | ${jq} -cS .)" = "$(echo "$updated" | ${jq} -cS .)" ]; then
            return 0
          fi

          echo "$updated" | api -X PUT -H 'Content-Type: application/json' -d @- \
            "${prowlarrUrl}/api/v1/indexer/$id" > /dev/null
          echo "Reconciled Prowlarr indexer '$name': $label"
        }

        ${lib.concatMapStringsSep "\n" (name: ''
          reconcile ${lib.escapeShellArg name} 'if (.tags | index($t)) then . else .tags += [$t] end' "via FlareSolverr"
        '') cfg.prowlarr.flaresolverrIndexers}

        ${lib.concatMapStringsSep "\n" (name: ''
          reconcile ${lib.escapeShellArg name} '(.fields[] | select(.name == "torrentBaseSettings.preferMagnetUrl") | .value) = false' "torrent file over magnet"
        '') cfg.prowlarr.torrentFileIndexers}
      '';

      # Sonarr and Radarr each store their own copy of the qBittorrent WebUI
      # password, so the secret lives in three places and a rotation breaks
      # downloads until every copy is updated by hand. Reconcile them from the
      # one file that is authoritative.
      #
      # The API masks password fields on read (`********`), so there is nothing
      # to diff against and the write is unconditional.
      clientSyncScript = pkgs.writeShellScript "servarr-sync-download-clients" ''
        set -euo pipefail

        password="$(< ${toString cfg.downloadClient.passwordFile})"

        sync_one() {
          local name="$1" port="$2" config="$3"
          local key base clients

          key="$(${sed} -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p' "$config")"
          if [ -z "$key" ]; then
            echo "Could not read $name's API key from $config." >&2
            return 1
          fi

          base="http://localhost:$port/api/v3"

          for attempt in $(seq 60); do
            status="$(${curl} -sS -o /dev/null -w '%{http_code}' \
              -H "X-Api-Key: $key" "$base/system/status" 2>/dev/null || true)"
            [ "$status" = "200" ] && break

            if [ "$attempt" -eq 60 ]; then
              echo "$name API never became ready on port $port (last HTTP $status)!" >&2
              return 1
            fi

            sleep 1
          done

          clients="$(${curl} -sS --fail-with-body -H "X-Api-Key: $key" "$base/downloadclient")"

          echo "$clients" \
            | ${jq} -c '.[] | select(.implementation == "QBittorrent")' \
            | while read -r client; do
                id="$(echo "$client" | ${jq} -r .id)"

                # forceSave skips the connection test the API runs on save.
                # Without it this cannot repair a wrong password: the *arr
                # service refuses the write with a 400 because it cannot reach
                # the client using the credential it is being handed, which is
                # exactly the state a rotation leaves behind.
                echo "$client" \
                  | ${jq} -c --arg u ${lib.escapeShellArg cfg.downloadClient.username} --arg p "$password" \
                      '.fields |= map(
                         if .name == "username" then .value = $u
                         elif .name == "password" then .value = $p
                         else . end
                       )' \
                  | ${curl} -sS --fail-with-body -X PUT \
                      -H "X-Api-Key: $key" -H 'Content-Type: application/json' \
                      -d @- "$base/downloadclient/$id?forceSave=true"

                echo "Reconciled $name download client: $(echo "$client" | ${jq} -r .name)"
              done
        }

        sync_one sonarr ${toString config.services.sonarr.settings.server.port} ${config.services.sonarr.dataDir}/config.xml
        sync_one radarr ${toString config.services.radarr.settings.server.port} ${config.services.radarr.dataDir}/config.xml
      '';

      # Radarr picks a root folder once, when the movie is added, and has no
      # rule for choosing a different one per title. Seerr's override rules are
      # the intended lever, but Seerr skips them for any requester holding
      # ADMIN or MANAGE_REQUESTS, so anything an admin requests lands on the
      # default root. Reconcile after the fact instead: both roots are the same
      # btrfs mount, so the move is a rename.
      animeRootSyncScript = pkgs.writeShellScript "radarr-sync-anime-root" ''
        set -euo pipefail

        key="$(${sed} -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p' ${config.services.radarr.dataDir}/config.xml)"
        if [ -z "$key" ]; then
          echo "Could not read Radarr's API key." >&2
          exit 1
        fi

        base="http://localhost:${toString config.services.radarr.settings.server.port}/api/v3"

        api() {
          ${curl} -sS --fail-with-body -H "X-Api-Key: $key" "$@"
        }

        # Timer-driven, so a Radarr that is down costs one skipped run rather
        # than a failed unit on every tick.
        for attempt in $(seq 30); do
          status="$(${curl} -sS -o /dev/null -w '%{http_code}' -H "X-Api-Key: $key" \
            "$base/system/status" 2>/dev/null || true)"
          [ "$status" = "200" ] && break

          if [ "$attempt" -eq 30 ]; then
            echo "Radarr API not ready (last HTTP $status); skipping this run." >&2
            exit 0
          fi

          sleep 1
        done

        tag_id="$(api "$base/tag" \
          | ${jq} -r --arg l ${lib.escapeShellArg animeTag} \
              'map(select(.label == $l)) | first | .id // empty')"

        if [ -z "$tag_id" ]; then
          tag_id="$(api -X POST -H 'Content-Type: application/json' \
            -d "$(${jq} -nc --arg l ${lib.escapeShellArg animeTag} '{label: $l}')" \
            "$base/tag" | ${jq} -r .id)"
          echo "Created Radarr tag: ${animeTag} (id $tag_id)"
        fi

        movies="$(api "$base/movie")"

        # Radarr carries TMDB's keyword list on the movie itself, so this
        # selects exactly what the Seerr override rule selects (keyword
        # 210024). index() is an exact element match, so the "animation"
        # keyword sitting next to it does not collide.
        select_ids() {
          echo "$movies" | ${jq} -c --arg root ${lib.escapeShellArg animeRoot} --argjson t "$tag_id" "$1"
        }

        untagged="$(select_ids '[.[]
          | select((.keywords // []) | index("anime"))
          | select((.tags | index($t)) | not)
          | .id]')"

        misplaced="$(select_ids '[.[]
          | select((.keywords // []) | index("anime"))
          | select(.rootFolderPath != $root)
          | .id]')"

        edit() {
          local ids="$1" body="$2" label="$3"

          # Not `[ ... ] && return`: under set -e a false test fails the list.
          if [ "$(echo "$ids" | ${jq} 'length')" -eq 0 ]; then
            return 0
          fi

          echo "$body" | api -X PUT -H 'Content-Type: application/json' -d @- \
            "$base/movie/editor" > /dev/null
          echo "Reconciled $(echo "$ids" | ${jq} 'length') movie(s): $label"
        }

        # Tag first: if the move then fails, the next run retries only what is
        # still wrong.
        edit "$untagged" \
          "$(${jq} -nc --argjson ids "$untagged" --argjson t "$tag_id" \
              '{movieIds: $ids, tags: [$t], applyTags: "add"}')" \
          "tagged ${animeTag}"

        edit "$misplaced" \
          "$(${jq} -nc --argjson ids "$misplaced" --arg root ${lib.escapeShellArg animeRoot} \
              '{movieIds: $ids, rootFolderPath: $root, moveFiles: true}')" \
          "moved to ${animeRoot}"
      '';
    in
    {
      options.servarr = {
        enable = lib.mkEnableOption "Enable the *arr stack.";

        prowlarr = {
          flaresolverrUrl = mkOption {
            type = types.str;
            default = "http://localhost:8191/";
            description = "Where Prowlarr reaches FlareSolverr.";
          };

          flaresolverrTag = mkOption {
            type = types.str;
            default = "cloudflare";
            description = "Prowlarr tag binding indexers to the FlareSolverr proxy. A proxy only applies to indexers sharing one of its tags.";
          };

          flaresolverrIndexers = mkOption {
            type = types.listOf types.str;
            default = [ ];
            example = [ "EZTV" ];
            description = ''
              Indexers that sit behind Cloudflare and must be routed through
              FlareSolverr. Without the tag, `services.flaresolverr.enable`
              runs a daemon that nothing ever consults, the indexer fails every
              query, and Prowlarr's own circuit breaker then answers Sonarr and
              Radarr with 429 for that indexer.
            '';
          };

          torrentFileIndexers = mkOption {
            type = types.listOf types.str;
            default = [ ];
            example = [ "AnimeTosho" ];
            description = ''
              Indexers where Prowlarr should hand over the .torrent URL rather
              than the magnet link.

              Prowlarr wraps every download link into a proxy URL, and .NET's
              `Uri` refuses anything past 65519 characters. A single release
              with a pathological tracker list is therefore enough to make the
              whole result page fail with a 500, which the *arr clients then
              record as an indexer failure. Torrent-file URLs have a bounded
              length, so they cannot trip it.
            '';
          };
        };

        radarr.syncAnimeRoot = lib.mkEnableOption ''
          Reconciling anime movies onto {file}`${animeRoot}`.

          Radarr picks a root folder once, when the movie is added, and has no
          rule for choosing a different one per title. Seerr's override rules
          are the intended lever, but Seerr skips them for any requester
          holding ADMIN or MANAGE_REQUESTS, so anything an admin requests lands
          on the default root instead
        '';

        downloadClient = {
          syncCredentials = lib.mkEnableOption ''
            Reconciling the qBittorrent download client credentials in Sonarr
            and Radarr from {option}`servarr.downloadClient.passwordFile`.

            The *arr services keep a copy of the WebUI password in their own
            database, so rotating the secret otherwise means editing it by hand
            in every UI, and downloads fail silently until you do
          '';

          username = mkOption {
            type = types.str;
            default = "admin";
            description = "WebUI username the *arr services authenticate with.";
          };

          passwordFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "File holding the qBittorrent WebUI password. Normally the sops secret the qBittorrent module already uses, so the secret has one home.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        # Each *arr keeps its library, history and indexer wiring in a SQLite DB
        # under its state directory. Prowlarr runs as a DynamicUser, so its real
        # state is under /var/lib/private and the /var/lib path is a symlink.
        persistence.directories = [
          {
            directory = "/var/lib/sonarr";
            user = config.services.sonarr.user;
            group = config.services.sonarr.group;
          }
          {
            directory = "/var/lib/radarr";
            user = config.services.radarr.user;
            group = config.services.radarr.group;
          }
          "/var/lib/private/prowlarr"
        ];

        users.extraGroups.media.members = [
          config.services.sonarr.user
          config.services.radarr.user
        ];

        # Acquisition-only roots for anime, kept out of the Jellyfin media tree:
        # Shoko is the librarian for anime, so these hold nothing Jellyfin
        # reads. Sonarr/Radarr hardlink-import here purely to track what they
        # already have.
        systemd = {
          tmpfiles.rules =
            let
              sonarr = config.services.sonarr;
              radarr = config.services.radarr;
            in
            [
              "d /srv/media/sonarr        2775 root         media - -"
              "d /srv/media/sonarr/anime  2770 ${sonarr.user} media - -"
              "d /srv/media/radarr        2775 root         media - -"
              "d ${animeRoot}  2770 ${radarr.user} media - -"

              # UMask below is 0002 so the media tree stays group-writable, which
              # also makes everything these services write under their own state
              # directory group- and world-readable. That state is not media: it
              # holds the API key in config.xml, and the download client password
              # in the database, which Sonarr and Radarr store in plaintext by
              # design (there is no encryption option to reach for). Upstream
              # already gives Radarr's dataDir 0700 but not Sonarr's.
              "d ${sonarr.dataDir} 0700 ${sonarr.user} ${sonarr.group} - -"
              "d ${radarr.dataDir} 0700 ${radarr.user} ${radarr.group} - -"

              # Heal state written before the above. `~` masks against the current
              # bits, so directories land on 0700 and plain files on 0600.
              "Z ${sonarr.dataDir} ~0700 ${sonarr.user} ${sonarr.group} - -"
              "Z ${radarr.dataDir} ~0700 ${radarr.user} ${radarr.group} - -"
            ];

          services =
            let
              serviceConfig = {
                unitConfig.RequiresMountsFor = [ "/srv/media" ];

                # Group-writable so the other `media` members (shoko, jellyfin)
                # can manage what these import. It is the wrong lever for the
                # state directory, which the tmpfiles rules above pin instead.
                serviceConfig.UMask = lib.mkForce "0002";
              };
            in
            {
              sonarr = lib.mkMerge [
                serviceConfig
                {
                  # Only Sonarr uses StateDirectory=, so this is the one service
                  # where the mode is not dead config. Without it systemd creates
                  # /var/lib/sonarr at 0755 and the chain above dataDir stays
                  # traversable. Radarr and Prowlarr get their own 0700 from
                  # upstream's tmpfiles rule and DynamicUser respectively.
                  serviceConfig.StateDirectoryMode = "0700";
                }
              ];

              radarr = serviceConfig;
              prowlarr = serviceConfig;

              servarr-sync-download-clients = lib.mkIf cfg.downloadClient.syncCredentials {
                description = "Reconcile *arr download client credentials";
                requires = [
                  "sonarr.service"
                  "radarr.service"
                ];

                after = [
                  "sonarr.service"
                  "radarr.service"
                  "qbittorrent.service"
                ];

                # Ordering only: the reconcile is worth doing even when the
                # client is down, so a rotation lands before the next retry.
                wants = [ "qbittorrent.service" ];
                wantedBy = [ "multi-user.target" ];
                restartTriggers = [ clientSyncScript ];

                serviceConfig = {
                  Type = "oneshot";

                  # Reads each service's config.xml, which is 0700-owned by its
                  # own user after the lockdown above.
                  ExecStart = clientSyncScript;
                };
              };

              prowlarr-sync-indexers =
                lib.mkIf (cfg.prowlarr.flaresolverrIndexers != [ ] || cfg.prowlarr.torrentFileIndexers != [ ])
                  {
                    description = "Reconcile Prowlarr indexer proxy and per-indexer settings";
                    requires = [ "prowlarr.service" ];
                    after = [
                      "prowlarr.service"
                      "flaresolverr.service"
                    ];

                    wants = [ "flaresolverr.service" ];
                    wantedBy = [ "multi-user.target" ];
                    restartTriggers = [ syncScript ];

                    serviceConfig = {
                      Type = "oneshot";

                      # Prowlarr is a DynamicUser, so its config.xml (and the API
                      # key in it) is only reachable as root.
                      ExecStart = syncScript;
                    };
                  };

              radarr-sync-anime-root = lib.mkIf cfg.radarr.syncAnimeRoot {
                description = "Reconcile Radarr's anime root folder";

                # Ordering only: the timer drives this, not multi-user.target.
                after = [ "radarr.service" ];
                wants = [ "radarr.service" ];
                restartTriggers = [ animeRootSyncScript ];

                serviceConfig = {
                  Type = "oneshot";

                  # Reads Radarr's config.xml, which the tmpfiles rules above pin
                  # to 0700 under its own user.
                  ExecStart = animeRootSyncScript;
                };
              };
            };

          # Unlike the reconcilers above, this one cannot be a boot-time oneshot:
          # movies are added at any hour. 15 minutes sits well inside a download,
          # so in practice the path is rewritten before anything imports and no
          # file ever moves.
          timers.radarr-sync-anime-root = lib.mkIf cfg.radarr.syncAnimeRoot {
            description = "Reconcile Radarr's anime root folder";
            wantedBy = [ "timers.target" ];

            timerConfig = {
              OnBootSec = "5m";
              OnUnitActiveSec = "15m";
            };
          };
        };

        services =
          let
            mkServarrConfig = port: {
              enable = true;
              openFirewall = false;
              settings = {
                update = {
                  automatically = false;
                  mechanism = "external";
                };

                server = {
                  inherit port;

                  bindaddress = "localhost";
                };

                log.analyticsEnabled = false;
              };
            };
          in
          {
            sonarr = mkServarrConfig 8989;
            radarr = mkServarrConfig 7878;
            prowlarr = mkServarrConfig 9696;

            flaresolverr = {
              enable = true;
              openFirewall = false;
            };
          };
      };
    };
}
