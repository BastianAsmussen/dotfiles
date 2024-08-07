{pkgs, ...}: {
  programs.tmux = {
    enable = true;

    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "screen-256color"; # Fix terminal colors.
    keyMode = "vi";

    newSession = true;
    secureSocket = true;

    escapeTime = 0; # Make pressing escape instant.
    prefix = "C-Space";
    mouse = true;

    aggressiveResize = true;
    disableConfirmationPrompt = true;
    baseIndex = 1;

    plugins = with pkgs.tmuxPlugins; [
      catppuccin
      yank
      vim-tmux-navigator
    ];

    extraConfig = ''
      # Fix terminal colors.
      set -as terminal-features ",xterm-256color:RGB"

      # Automatically renumber windows.
      set-option -g renumber-windows on

      # Keybindings for yanking.
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Open panes and windows in the current directory.
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Shift-ALT Vim keys to switch windows.
      bind -n M-H previous-window
      bind -n M-L next-window
    '';
  };
}
