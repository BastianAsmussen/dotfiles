{
  flake.homeModules.tmuxSessionizer = {
    pkgs,
    config,
    ...
  }: {
    home.packages = [pkgs.tmux-sessionizer];

    xdg.configFile."tms/config.toml".source = let
      home = config.home.homeDirectory;
    in
      (pkgs.formats.toml {}).generate "tms-config" {
        session_sort_order = "LastAttached";

        search_dirs =
          map (dir: {
            inherit (dir) depth;

            path = "${home}/${dir.path}";
          }) [
            {
              path = "Projects";
              depth = 2;
            }
            {
              path = "dotfiles";
              depth = 1;
            }
            {
              path = "nix-secrets";
              depth = 1;
            }
          ];
      };
  };
}
