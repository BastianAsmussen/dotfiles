{ inputs, ... }:
{
  flake.homeModules.jujutsu =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # Per-repo config and metadata; `config.toml` beside it is HM-managed.
      persistence.directories = [ ".config/jj/repos" ];

      programs.jujutsu = {
        enable = true;

        settings = {
          user = {
            inherit (inputs.nix-secrets.user) email;

            name = inputs.nix-secrets.user.full-name;
          };

          signing = {
            behavior = "own";
            backend = "gpg";
            key = config.programs.git.signing.key;
          };

          ui = {
            default-command = "log";
            pager = lib.getExe pkgs.delta;
            diff-formatter = ":git";
            diff-editor = ":builtin";
          };

          git = {
            sign-on-push = true;
            write-change-id-header = true;
          };
        };
      };
    };
}
