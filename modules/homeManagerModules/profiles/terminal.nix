# Terminal profile for desktop, laptop and phone hosts.
{ self, ... }:
{
  flake.homeModules.terminal = {
    imports = with self.homeModules; [
      bat
      btop
      direnv
      distrobox
      eza
      fastfetch
      fzf
      git
      gpg
      jujutsu
      nixIndex
      nixvim
      ohMyPosh
      gopass
      ripgrep
      tmux
      tmuxSessionizer
      tuxedo
      zoxide
      zsh
    ];
  };
}
