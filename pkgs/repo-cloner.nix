{
  pkgs,
  lib,
  ...
}: let
  inherit (lib) getExe;
in
  pkgs.writeShellScriptBin "repo-cloner" ''
    # @describe Clone and sync all GitHub repositories, sorting them into Personal/ and School/ directories.
    # Repositories are classified as school projects if their name matches the
    # pattern "H[1-6]_" or "H[1-6]-" (case-insensitive), or if their description
    # contains "school" or "skole".
    #
    # If a repository already exists locally:
    #   - If the working tree is clean, pull the latest changes.
    #   - If there are local changes, skip it to avoid conflicts.
    #
    # @meta version 0.1.0
    # @meta author Bastian Asmussen <bastian@asmussen.tech>
    # @option -u --username=''${GITHUB_USERNAME:-} <USERNAME> GitHub username
    # @option -t --token=''${GITHUB_TOKEN:-} <TOKEN> GitHub Personal Access Token
    # @option -d --directory=~/Projects <DIR> Root directory for cloned repositories
    # @flag --no-depth Clone with full history instead of shallow (--depth=1)

    function main {
      set -euo pipefail

      if [ -z "$argc_username" ]; then
        echo "Error: No GitHub username provided."
        echo "Either set GITHUB_USERNAME or pass --username."
        exit 1
      fi

      if [ -z "$argc_token" ]; then
        echo "Error: No GitHub token provided."
        echo "Either set GITHUB_TOKEN or pass --token."
        echo "Create a Personal Access Token at https://github.com/settings/tokens"
        exit 1
      fi

      local root_dir="$argc_directory"
      local personal_dir="''${root_dir}/Personal"
      local school_dir="''${root_dir}/School"

      echo "Fetching repository list for ''${argc_username}..."

      ssh_urls=()
      descriptions=()
      local page=1

      while :; do
        response=$(${getExe pkgs.curl} -s \
          -H "Authorization: token ''${argc_token}" \
          -H "Accept: application/vnd.github+json" \
          "https://api.github.com/users/''${argc_username}/repos?per_page=100&page=''${page}&type=owner")

        count=$(echo "$response" | ${getExe pkgs.jq} '. | length')
        if [ "$count" -eq 0 ]; then
          break
        fi

        while IFS= read -r entry; do
          ssh_urls+=("$(echo "$entry" | ${getExe pkgs.jq} -r '.ssh_url')")
          descriptions+=("$(echo "$entry" | ${getExe pkgs.jq} -r '.description // ""')")
        done < <(echo "$response" | ${getExe pkgs.jq} -c '.[]')

        page=$((page + 1))
      done

      local total=''${#ssh_urls[@]}

      if [ "$total" -eq 0 ]; then
        echo "No repositories found for ''${argc_username}."
        exit 1
      fi

      echo "Found ''${total} repositories."

      mkdir -p "$personal_dir" "$school_dir"

      local personal_count=0
      local school_count=0
      local cloned_count=0
      local pulled_count=0
      local skipped_count=0

      local depth_args=(--depth=1)
      if [ "''${argc_no_depth:-}" ]; then
        depth_args=()
      fi

      shopt -s nocasematch

      for i in "''${!ssh_urls[@]}"; do
        local url="''${ssh_urls[$i]}"
        local desc="''${descriptions[$i]}"
        local name
        name=$(basename "$url" .git)

        # Determine the target directory:
        #   1. Name matches "H[1-6]" followed by _ or - (case-insensitive) -> School
        #   2. Description contains "school" or "skole" (case-insensitive) -> School
        #   3. Everything else -> Personal
        local target_dir
        local category
        if [[ "$name" =~ ^H[1-6][_\-] ]] || [[ "$desc" =~ school|skole ]]; then
          target_dir="$school_dir"
          category="School"
          school_count=$((school_count + 1))
        else
          target_dir="$personal_dir"
          category="Personal"
          personal_count=$((personal_count + 1))
        fi

        local repo_path="''${target_dir}/''${name}"

        echo ""
        echo "[$((i + 1))/''${total}] [''${category}] ''${name}"

        if [ -d "$repo_path/.git" ]; then
          # Repo already exists — check for local changes.
          if ${getExe pkgs.git} -C "$repo_path" diff --quiet && ${getExe pkgs.git} -C "$repo_path" diff --staged --quiet; then
            echo "  -> Already exists, working tree clean. Pulling latest changes..."

            ${getExe pkgs.git} -C "$repo_path" pull --ff-only || echo "  -> Pull failed (e.g., diverged history), skipping."
            pulled_count=$((pulled_count + 1))
          else
            echo "  -> Already exists, local changes detected. Skipping to avoid conflicts."
            skipped_count=$((skipped_count + 1))
          fi
        else
          echo "  -> Cloning..."
          ${getExe pkgs.git} clone "''${depth_args[@]}" "$url" "$repo_path" || echo "  -> Failed to clone ''${name}, skipping."

          cloned_count=$((cloned_count + 1))
        fi
      done

      shopt -u nocasematch

      echo ""
      echo "Done!"
      echo "  Personal: ''${personal_count} repositories -> ''${personal_dir}"
      echo "  School:   ''${school_count} repositories -> ''${school_dir}"
      echo ""
      echo "  Cloned:   ''${cloned_count}"
      echo "  Pulled:   ''${pulled_count}"
      echo "  Skipped:  ''${skipped_count} (had local changes)"
    }

    eval "$(${getExe pkgs.argc} --argc-eval "$0" "$@")"
  ''
