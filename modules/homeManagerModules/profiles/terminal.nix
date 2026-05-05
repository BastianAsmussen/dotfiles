# Full terminal environment shared across all desktop/laptop/phone hosts.
# Server hosts (eta) intentionally omit this as they use a smaller explicit set.
{self, ...}: {
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
      passwordStore
      ripgrep
      tmux
      tmuxSessionizer
      zoxide
      zsh
    ];
  };
}
