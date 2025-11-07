{
  lib,
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: {
    packages.environment = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;

      package = self'.packages.fish;
      runtimeInputs = with pkgs; [
        # Nix.
        nil
        nixd
        statix
        alejandra
        manix
        nix-inspect
        self'.packages.nh

        # Other.
        file
        unzip
        zip
        p7zip
        wget
        killall
        sshfs
        fzf
        htop
        btop
        eza
        fd
        zoxide
        dust
        ripgrep
        neofetch
        tree-sitter
        imagemagick
        imv
        ffmpeg
        yt-dlp
        lazygit

        # Wrapped.
        self'.packages.neovim
        self'.packages.qalc
        self'.packages.lf
        self'.packages.git
      ];

      env.EDITOR = "${lib.getExe self'.packages.neovim}";
    };
  };
}
