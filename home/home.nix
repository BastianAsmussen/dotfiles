{ inputs, config, pkgs, ... }:
{
  programs.home-manager.enable = true;

  programs = {
    tmux = (import ./tmux.nix { inherit pkgs; });
    zsh = (import ./zsh.nix { inherit config pkgs; });
    #neovim = (import ./neovim.nix { inherit config pkgs; });
    git = (import ./git.nix { inherit config pkgs; });
    alacritty = (import ./alacritty.nix { inherit config pkgs; });
    gpg = (import ./gpg.nix { inherit config pkgs; });
    #firefox = (import ./firefox.nix { inherit pkgs; });
    zoxide = (import ./zoxide.nix { inherit pkgs; });
    fzf = (import ./fzf.nix { inherit pkgs; });
  };

  home.stateVersion = "24.05";
}

