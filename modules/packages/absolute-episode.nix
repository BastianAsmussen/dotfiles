{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages.absolute-episode =
        let
          inherit (lib) getExe;

          curl = getExe pkgs.curl;
          jq = getExe pkgs.jq;
          fzf = getExe pkgs.fzf;
          argc = getExe pkgs.argc;
        in
        pkgs.writeShellScriptBin "abs-ep" ''
          # @describe Look up the absolute episode number behind a
          # streaming-style SxxEyy reference, e.g. One Piece S23E22 is
          # episode 1177.
          #
          # Streaming platforms split shows into seasons, numbered after
          # TheTVDB/TMDB, while MAL and AniDB count 1..N with no season
          # concept. This fetches the season list from TMDB and sums the
          # episode counts of every preceding season. Season 0 (specials)
          # is excluded. Optionally cross-references the result on
          # MyAnimeList via the Jikan API.
          #
          # Requires a TMDB API key (free at https://www.themoviedb.org/settings/api)
          # set via the TMDB_API_KEY environment variable.
          #
          # @meta version 0.2.0
          # @option -e --episode <S2E11> Episode reference, either order
          # @option -t --tmdb-id <ID> TMDB series ID to query
          # @option -q --query <TITLE> Search TMDB by title and pick with fzf
          # @option -m --mal-id <ID> Also look up the episode on MyAnimeList via Jikan

          function main {
              if [ -z "''${TMDB_API_KEY:-}" ]; then
                  echo "TMDB_API_KEY is not set." >&2
                  echo "Get a free key at https://www.themoviedb.org/settings/api" >&2
                  exit 1
              fi

              if [ -z "$argc_tmdb_id" ] && [ -z "$argc_query" ]; then
                  echo "Provide a show with -t/--tmdb-id <ID> or -q/--query <TITLE>." >&2
                  exit 1
              fi

              local season episode
              if [[ "$argc_episode" =~ ^[Ss]([0-9]+)[Ee]([0-9]+)$ ]]; then
                  season="''${BASH_REMATCH[1]}"
                  episode="''${BASH_REMATCH[2]}"
              elif [[ "$argc_episode" =~ ^[Ee]([0-9]+)[Ss]([0-9]+)$ ]]; then
                  episode="''${BASH_REMATCH[1]}"
                  season="''${BASH_REMATCH[2]}"
              else
                  echo "Provide an episode with -e/--episode <SxxEyy>, e.g. S23E22." >&2
                  exit 1
              fi

              local tmdb_id="$argc_tmdb_id"
              if [ -n "$argc_query" ]; then
                  local encoded_query
                  encoded_query=$(${jq} -rn --arg q "$argc_query" '$q|@uri')

                  tmdb_id=$(${curl} -s "https://api.themoviedb.org/3/search/tv?api_key=$TMDB_API_KEY&query=$encoded_query" \
                      | ${jq} -r '.results[] | "\(.id)\t\(.name) (\(.first_air_date // "?" | split("-")[0]))"' \
                      | ${fzf} --delimiter='\t' --with-nth=2.. \
                      | cut -f1)

                  if [ -z "$tmdb_id" ]; then
                      echo "No show selected, aborting." >&2
                      exit 1
                  fi
              fi

              # Fetch series metadata from TMDB.
              local series_json
              series_json=$(${curl} -s "https://api.themoviedb.org/3/tv/$tmdb_id?api_key=$TMDB_API_KEY")

              local show_name
              show_name=$(echo "$series_json" | ${jq} -r '.name')

              # Compute absolute episode number by summing episode counts of
              # all regular seasons before the requested one. Season 0
              # (specials) is excluded.
              local absolute
              absolute=$(echo "$series_json" | ${jq} -r \
                  --arg s "$season" \
                  --arg e "$episode" \
                  '[.seasons[] | select(.season_number > 0 and .season_number < ($s | tonumber))]
                   | map(.episode_count) | add // 0
                   | . + ($e | tonumber)')

              # Fetch episode details from TMDB.
              local ep_json
              ep_json=$(${curl} -s "https://api.themoviedb.org/3/tv/$tmdb_id/season/$season/episode/$episode?api_key=$TMDB_API_KEY")

              local ep_name ep_aired
              ep_name=$(echo "$ep_json" | ${jq} -r '.name // "n/a"')
              ep_aired=$(echo "$ep_json" | ${jq} -r '.air_date // "n/a"')

              echo "$show_name S''${season}E$episode = episode $absolute"
              echo "Title: $ep_name"
              echo "Aired: $ep_aired"

              # Optional MAL lookup.
              if [ -n "$argc_mal_id" ]; then
                  echo ""
                  ${curl} -s "https://api.jikan.moe/v4/anime/$argc_mal_id/episodes/$absolute" \
                      | ${jq} -r '.data | "MAL: \(.title)\n     \(.url)"'
              fi
          }

          eval "$(${argc} --argc-eval "$0" "$@")"
        ''
        // {
          meta = with lib; {
            description = "Look up the absolute episode number behind a streaming SxxEyy reference via TMDB, with optional MAL lookup.";
            license = licenses.mit;
            maintainers = [ maintainers.BastianAsmussen ];
            platforms = platforms.unix;
            mainProgram = "abs-ep";
          };
        };
    };
}
