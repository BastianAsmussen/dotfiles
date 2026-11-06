set -euo pipefail

die() {
  printf '\033[1;31m✗\033[0m %b\n' "$1" >&2
  sleep 2
  exit 1
}

info() {
  printf '\033[1;34m›\033[0m %b\n' "$1"
}

ok() {
  printf '\033[1;32m✓\033[0m %b\n' "$1"
}

category=$(
  printf 'Personal\nSchool' |
    fzf --prompt=' Category › ' \
      --height=~50% \
      --reverse \
      --no-info \
      --border=rounded \
      --border-label=' Clone Project ' \
      --color='pointer:blue,prompt:blue,border:dim'
)

printf '\033[1;34m›\033[0m Repo \033[2m(owner/repo or full URL)\033[0m: '
if ! read -e -r repo_input; then
  exit 0
fi
if [ -z "$repo_input" ]; then
  exit 0
fi

if [[ "$repo_input" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then
  repo_url="git@github.com:${repo_input%.git}.git"
else
  repo_url=${repo_input%/}
fi

project_name=$(basename "$repo_url" .git)
if [[ -z "$project_name" || "$project_name" == "." || "$project_name" == ".." || "$project_name" == */* ]]; then
  die "Could not determine a valid project name."
fi

category_dir="${HOME}/Projects/${category}"
target_dir="${category_dir}/${project_name}"
clone_dir=

cleanup() {
  if [ -n "$clone_dir" ] && [ -d "$clone_dir" ]; then
    rm -rf -- "$clone_dir"
  fi
}
trap cleanup EXIT

if [ -e "$target_dir" ]; then
  if [ ! -d "$target_dir" ] || [ ! -e "$target_dir/.git" ]; then
    die "Target exists but is not a Git repository: ${target_dir}"
  fi

  info "Already exists, opening \033[1m${project_name}\033[0m"
else
  info "Cloning into \033[2m${target_dir}\033[0m"
  printf '\n'

  mkdir -p -- "$category_dir"
  clone_dir=$(mktemp -d "${target_dir}.tmp.XXXXXX")
  log_file=$(mktemp "${TMPDIR:-/tmp}/clone-project.XXXXXX")

  # Stream the original failure and preserve it; never retry into the same path.
  if ! git clone --progress -- "$repo_url" "$clone_dir" 2>&1 | tee "$log_file"; then
    die "Clone failed, see \033[4m${log_file}\033[0m"
  fi

  if ! mv -T -- "$clone_dir" "$target_dir"; then
    die "Clone succeeded, but could not move it to \033[4m${target_dir}\033[0m"
  fi
  clone_dir=
  rm -f -- "$log_file"

  printf '\n'
  ok "Cloned \033[1m${project_name}\033[0m"
fi

session_name=$(printf '%s' "$project_name" | tr '.:' '--')
if ! tmux has-session -t "=${session_name}" 2>/dev/null; then
  if ! tmux new-session -d -s "$session_name" -c "$target_dir"; then
    die "Could not create tmux session \033[1m${session_name}\033[0m"
  fi
fi

if ! tmux switch-client -t "=${session_name}"; then
  die "Could not switch to tmux session \033[1m${session_name}\033[0m"
fi
