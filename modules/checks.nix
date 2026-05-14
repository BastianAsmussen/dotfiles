{
  perSystem =
    { pkgs, ... }:
    {
      # Individual library tests are registered as their own
      # checks from modules/tests/**.nix.
      checks = {
        # Check for dead Nix code.
        deadnix =
          pkgs.runCommandLocal "deadnix"
            {
              buildInputs = [ pkgs.deadnix ];
              src = ../.;
            }
            ''
              deadnix --fail "$src"
              touch $out
            '';

        # Lint Nix files.
        statix =
          pkgs.runCommandLocal "statix"
            {
              buildInputs = [ pkgs.statix ];
              src = ../.;
            }
            ''
              statix check "$src"
              touch $out
            '';

        # Check flake inputs.
        flake-checker =
          pkgs.runCommandLocal "flake-checker"
            {
              buildInputs = [ pkgs.flake-checker ];
              src = ../.;
            }
            ''
              flake-checker --fail-mode --no-telemetry "$src/flake.lock"
              touch $out
            '';
      };
    };
}
