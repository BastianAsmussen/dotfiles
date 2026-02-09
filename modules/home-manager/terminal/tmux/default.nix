{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) getExe;

  tmux = getExe pkgs.tmux;
  tms = getExe pkgs.tmux-sessionizer;

  sessionPopup = pkgs.writeShellScriptBin "sessions" ''
    raw_width=$(${tmux} display-message -p '#{window_width}')
    raw_height=$(${tmux} display-message -p '#{window_height}')

    popup_width=$((raw_width > 100 ? 100 : raw_width * 80 / 100))
    popup_height=$((raw_height > 50 ? 50 : raw_height * 80 / 100))

    ${tmux} display-popup -E -h $popup_height -w $popup_width -T 'Choose Project' '${tms}'
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

      # Detach from current session.
      bind C-d detach-client
    '';
  };
}
