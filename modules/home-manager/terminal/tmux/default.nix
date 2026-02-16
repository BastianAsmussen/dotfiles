{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) getExe;

  tmux = getExe pkgs.tmux;
  tms = getExe pkgs.tmux-sessionizer;
  fzf = getExe pkgs.fzf;
  git = getExe pkgs.git;

  homeDir = config.home.homeDirectory;
  logFile = "/tmp/clone-project.log";

  sessionPopup = pkgs.writeShellScriptBin "sessions" ''
    raw_width=$(${tmux} display-message -p '#{window_width}')
    raw_height=$(${tmux} display-message -p '#{window_height}')

    popup_width=$((raw_width > 100 ? 100 : raw_width * 80 / 100))
    popup_height=$((raw_height > 50 ? 50 : raw_height * 80 / 100))

    ${tmux} display-popup -E -h $popup_height -w $popup_width -T 'Choose Project' '${tms}'
  '';

  cloneProject = pkgs.writeShellScriptBin "clone-project" ''
    set -euo pipefail

    # ── Helpers ──────────────────────────────────────────────
    die()  { printf '\033[1;31m✗\033[0m %b\n' "$1"; sleep 2; exit 1; }
    info() { printf '\033[1;34m›\033[0m %b\n' "$1"; }
    ok()   { printf '\033[1;32m✓\033[0m %b\n' "$1"; }

    # ── 1. Category ──────────────────────────────────────────
    category=$(printf 'Personal\nSchool' \
      | ${fzf} --prompt=' Category › ' \
              --height=~50% \
              --reverse \
              --no-info \
              --border=rounded \
              --border-label=' Clone Project ' \
              --color='pointer:blue,prompt:blue,border:dim')
    [ -z "''${category:-}" ] && exit 0

    # ── 2. Repository URL ────────────────────────────────────
    printf '\033[1;34m›\033[0m Repo \033[2m(owner/repo or full URL)\033[0m: '
    read -r repo_input
    [ -z "''${repo_input:-}" ] && exit 0

    # Expand owner/repo shorthand → SSH URL.
    if echo "$repo_input" | grep -qE '^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$'; then
      repo_url="git@github.com:''${repo_input}.git"
    else
      repo_url="$repo_input"
    fi

    project_name=$(basename "$repo_url" .git)
    target_dir="${homeDir}/Projects/''${category}/''${project_name}"

    # ── 3. Clone / reuse ─────────────────────────────────────
    if [ -d "$target_dir" ]; then
      info "Already exists – opening \033[1m$project_name\033[0m"
    else
      info "Cloning into \033[2m$target_dir\033[0m …"
      printf '\n'

      if ! ${git} clone --progress "$repo_url" "$target_dir" 2>&1; then
        # Re-run to capture the error into the log.
        ${git} clone "$repo_url" "$target_dir" > "${logFile}" 2>&1 || true
        printf '\n'
        die "Clone failed – see \033[4m${logFile}\033[0m"
      fi

      printf '\n'
      ok "Cloned \033[1m$project_name\033[0m"
    fi

    # ── 4. Sessionize ────────────────────────────────────────
    session_name=$(echo "$project_name" | tr '.' '-')
    if ! ${tmux} has-session -t "=$session_name" 2>/dev/null; then
      ${tmux} new-session -d -s "$session_name" -c "$target_dir"
    fi
    ${tmux} switch-client -t "$session_name"
  '';
in {
  imports = [
    ./tmux-sessionizer.nix
  ];

  stylix.targets.tmux.enable = false;
  programs.tmux = {
    enable = true;

    shell = getExe pkgs.zsh;
    terminal = "screen-256color"; # Fix terminal colors.
    keyMode = "vi";

    newSession = true;
    secureSocket = true;

    escapeTime = 0; # Make pressing escape instant.
    prefix = "C-Space";
    mouse = true;
    clock24 = true;

    aggressiveResize = true;
    disableConfirmationPrompt = true;
    baseIndex = 1;

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      yank
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
          set -g @catppuccin_window_status_style 'basic'
          set -g @catppuccin_window_tabs_enabled on
          set -g @catppuccin_date_time "%H:%M"
        '';
      }
    ];

    extraConfig = ''
      # Fix terminal colors.
      set -as terminal-features ",xterm-256color:RGB"

      # Automatically renumber windows.
      set -g renumber-windows on

      # Keybindings for yanking.
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Open panes and windows in the current directory.
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Shift-ALT Vim keys to switch windows.
      bind -n M-l next-window
      bind -n M-h previous-window

      # Swap current and previous pane positions.
      bind -n C-g swap-pane -dUZ

      # Switch panes.
      bind -r k select-pane -UZ\; refresh-client -S
      bind -r j select-pane -DZ\; refresh-client -S
      bind -r h select-pane -LZ\; refresh-client -S
      bind -r l select-pane -RZ\; refresh-client -S

      bind -r ')' switch-client -n\; refresh-client -S
      bind -r '(' switch-client -p\; refresh-client -S

      # Resizing panes.
      bind -r M-Up resize-pane -U 5
      bind -r M-Down resize-pane -D 5
      bind -r M-Left resize-pane -L 5
      bind -r M-Right resize-pane -R 5

      bind -r C-Up resize-pane -U
      bind -r C-Down resize-pane -D
      bind -r C-Left resize-pane -L
      bind -r C-Right resize-pane -R

      # Sessionizer.
      bind s display-popup -E -h 60% -w 85% -T 'Active Sessions' "${tms} switch"
      bind w display-popup -E -h 60% -w 85% -T 'Session Windows' "${tms} windows"
      bind f run-shell "${getExe sessionPopup}"

      # Clone a new project and sessionize it.
      bind g display-popup -E -h 14 -w 64 -T ' Clone Project ' "${getExe cloneProject}"

      # Detach from current session.
      bind C-d detach-client
    '';
  };
}
