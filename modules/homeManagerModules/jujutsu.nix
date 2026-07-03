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
          };

          git = {
            sign-on-push = true;
            write-change-id-header = true;
          };
        };
      };
    };
}
