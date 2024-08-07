{
  lib,
  hmOptions,
  pkgs,
  ...
}: {
  imports = [
    ./goxlr
    ./hyprland
    ./nixvim
    ./oh-my-posh
    ./zsh
    ./alacritty.nix
    ./btop.nix
    ./devenv.nix
    ./eza.nix
    ./fastfetch.nix
    ./firefox.nix
    ./fzf.nix
    ./git.nix
    ./gpg.nix
    ./mpv.nix
    ./nixcord.nix
    ./password-store.nix
    ./qbittorrent.nix
    ./tmux.nix
    ./zoxide.nix
  ];

  gpg.enable = true;

  programs = {
    qbittorrent = {
      enable = true;

      legalNotice = true;
    };
    man.generateCaches = true;
  };

  home = {
    username = "${hmOptions.username}";
    homeDirectory = "/home/${hmOptions.username}";

    packages = with pkgs; [
      ripgrep
      gitui
      wget
      go
      manix
      teams-for-linux
      bitwarden
      spotify
    ];

    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs.
  systemd.user.startServices = "sd-switch";
}
