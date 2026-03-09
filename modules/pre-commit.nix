{inputs, ...}: {
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
      alejandra.enable = true;
      flake-checker = {
        enable = true;
        args = ["--no-telemetry"];
      };
    };
  };
}
