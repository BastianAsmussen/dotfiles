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

      curl = getExe pkgs.curl;
      jq = getExe pkgs.jq;

      # Prowlarr keeps indexers in its own SQLite DB, so the only way to make
      # any of this declarative is to reconcile it through the API on
      # activation, the way qbittorrent-sync-categories does for categories.
      syncScript = pkgs.writeShellScript "prowlarr-sync-indexers" ''
        set -euo pipefail

        key="$(${lib.getExe' pkgs.gnused "sed"} -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p' /var/lib/prowlarr/config.xml)"
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
        systemd.tmpfiles.rules =
          let
            sonarr = config.services.sonarr;
            radarr = config.services.radarr;
          in
          [
            "d /srv/media/sonarr        2775 root         media - -"
            "d /srv/media/sonarr/anime  2770 ${sonarr.user} media - -"
            "d /srv/media/radarr        2775 root         media - -"
            "d /srv/media/radarr/anime  2770 ${radarr.user} media - -"

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

        systemd.services =
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
