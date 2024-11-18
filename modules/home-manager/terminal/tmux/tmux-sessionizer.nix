{
  pkgs,
  config,
  ...
}: {
  home.packages = [pkgs.tmux-sessionizer];
  xdg.configFile."tms/config.toml".text = let
    inherit (config.home) homeDirectory;
  in
    # toml
    ''
      session-sort-order = "LastAttached"

      [[search_dirs]]
      path = "${homeDirectory}/Projects"
      depth = 1

      [[search_dirs]]
      path = "${homeDirectory}/dotfiles"
      depth = 1
    '';
}
