{
  imports = [
    ./lf
    ./nixvim
    ./zsh
    ./btop.nix
    ./devenv.nix
    ./distrobox.nix
    ./eza.nix
    ./fastfetch.nix
    ./fzf.nix
    ./git.nix
    ./gpg.nix
    ./oh-my-posh.nix
    ./password-store.nix
    ./ripgrep.nix
    ./tmux.nix
    ./zoxide.nix
  ];

  programs.bat.enable = true;
}
