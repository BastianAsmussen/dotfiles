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
      nixIndex
      nixvim
      ohMyPosh
      opencode
      gopass
      ripgrep
      tmux
      tmuxSessionizer
      zoxide
      zsh
    ];
  };
}
