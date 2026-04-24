# Full terminal environment shared across all desktop/laptop/phone hosts.
# Server hosts (eta) intentionally omit this as they use a smaller explicit set.
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
      passwordStore
    ];
  };
}
