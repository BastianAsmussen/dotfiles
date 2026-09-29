{
  inputs,
  config,
  lib,
  ...
}:
let
  hits = config.customLib.privateInputAccess;
in
{
  imports = [
    inputs.pre-commit-hooks.flakeModule
  ];

  perSystem =
    { pkgs, ... }:
    {
      pre-commit.settings.hooks = {
        deadnix = {
          enable = true;
          settings.edit = true;
        };

        statix.enable = true;
        nixfmt.enable = true;
        flake-checker = {
          enable = true;
          args = [ "--no-telemetry" ];
        };

        check-yaml.enable = true;
        ripsecrets.enable = true;

        private-input-access = {
          enable = true;
          name = "private-input-access";
          description = "Use private flake inputs through their outputs, never their source.";
          files = "\\.nix$";
          pass_filenames = false;
          entry = toString (
            pkgs.writeShellScript "private-input-access" (
              lib.optionalString (hits != [ ]) ''
                printf '%s\n' ${lib.escapeShellArgs hits}
                echo "Use the input's outputs (packages, overlays, nixosModules, sopsFiles, hosts, user), not its source." >&2
                exit 1
              ''
            )
          );
        };
      };
    };
}
