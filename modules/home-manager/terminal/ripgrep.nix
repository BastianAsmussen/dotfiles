{
  programs.ripgrep = {
    enable = true;

    arguments = [
      # Don't let ripgrep vomit really long lines to my terminal, and show a preview.
      "--max-columns=128"
      "--max-columns-preview"

      # Add 'web' type.
      "--type-add=web:*.{html,css,js}*"

      # Search hidden files / directories (e.g. dotfiles) by default.
      "--hidden"

      # Using glob patterns to include/exclude files or folders.
      "--glob=!.git/*"
      "--glob=!vendor/*"

      # Set the colors.
      "--colors=line:none"
      "--colors=line:style:bold"

      # Because who cares about case!?
      "--smart-case"
    ];
  };

  # Search by file names.
  home.shellAliases.rgf = "rg --files | rg";
}
