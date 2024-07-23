{pkgs, ...}: {
  programs.tmux = {
    enable = true;

    shell = "${pkgs.zsh}/bin/zsh";

    aggressiveResize = true;
    disableConfirmationPrompt = true;

    baseIndex = 1;

    terminal = "screen-256color"; # Fix terminal colors.
    keyMode = "vi";
    newSession = true;
    secureSocket = true;

    escapeTime = 0; # Make pressing escape instant.

    prefix = "C-Space";
    mouse = true;

    plugins = with pkgs.tmuxPlugins; [
      catppuccin
      yank
      vim-tmux-navigator
    ];

    extraConfig = ''
      # Fix terminal colors.
      set -as terminal-features ",xterm-256color:RGB"

      # Vim style pane selection.
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Keybindings.
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Start window and pane indexing at 1.
      set -g pane-base-index 1

      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      # Open panes in current directory.
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # Clear screen.
      bind L send-keys '^L'
    '';
  };
}
