{ inputs, config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should manage.
  home = {
    username = "bastian";
    homeDirectory = "/home/bastian";
    stateVersion = "23.11";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs = {
    zsh = (import ./zsh.nix { inherit config pkgs; });
    zoxide = (import ./zoxide.nix { inherit pkgs; });
    fzf = (import ./fzf.nix { inherit pkgs; });
  };
}
