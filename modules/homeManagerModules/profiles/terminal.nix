# Terminal profile for desktop, laptop and phone hosts.
{self, ...}: {
  flake.homeModules.terminal = {
    imports = with self.homeModules; [
      nixvim
      git
      zsh
      zoxide
      nixIndex
      tmux
      tmuxSessionizer
      gpg
      ohMyPosh
      bat
      btop
      direnv
      distrobox
      eza
      fastfetch
      fzf
      ripgrep
    ];
  };
}
