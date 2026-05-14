{ inputs, ... }:
{
  imports = [
    inputs.pre-commit-hooks.flakeModule
  ];

  perSystem = {
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

      trim-trailing-whitespace.enable = true;
      end-of-file-fixer.enable = true;
      check-yaml.enable = true;
    };
  };
}
