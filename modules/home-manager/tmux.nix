{pkgs, ...}: {
  programs.tmux = {
    enable = true;

    shell = "${pkgs.zsh}/bin/zsh";

    aggressiveResize = true;
    baseIndex = 1;
    disableConfirmationPrompt = true;

    terminal = "screen-256color"; # Fix terminal colors.
    keyMode = "vi";
    newSession = true;
    secureSocket = true;

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

      # Set Catppuccin theme.
      set -g @catppuccin_flavour 'mocha'

      # Keybindings.
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      bind L send-keys '^L' # Clear screen.

      # Open panes in current directory.
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
    '';
  };
}
