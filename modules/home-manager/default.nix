{
  hmOptions,
  pkgs,
  ...
}: {
  imports = [
    ./goxlr
    ./hyprland
    ./nixvim
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
    ./oh-my-posh.nix
    ./password-store.nix
    ./tmux.nix
    ./zoxide.nix
  ];

  gpg = {
    enable = true;

    keyTrustMap."0x0FE5A355DBC92568-2024-08-09.asc" = "ultimate";
  };

  programs.man.generateCaches = true;

  home = {
    username = "${hmOptions.username}";
    homeDirectory = "/home/${hmOptions.username}";

    packages = with pkgs; [
      qbittorrent
      ripgrep
      gitui
      wget
      go
      manix
      teams-for-linux
      bitwarden
      spotify
      pika-backup
    ];

    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs.
  systemd.user.startServices = "sd-switch";
}
