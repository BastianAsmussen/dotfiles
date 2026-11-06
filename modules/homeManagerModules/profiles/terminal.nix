# Terminal profile for desktop, laptop and phone hosts.
{ self, ... }:
{
  flake.homeModules.terminal = {
    imports = with self.homeModules; [
      bash
      bat
      btop
      claudeCode
      direnv
      distrobox
      dsh
      eza
      fastfetch
      fish
      fzf
      git
      gpg
      jujutsu
      kimiCode
      nixIndex
      nixvim
      ohMyPosh
      gopass
      ripgrep
      tmux
      tmuxSessionizer
      tuxedo
      uv
      zoxide
    ];
  };
}
