{ self, ... }:
{
  perSystem =
    {
      pkgs,
      config,
      lib,
      system,
      ...
    }:
    let
      # `caddy adapt` catches syntax and unknown-directive errors without
      # needing certificates.
      caddyfile =
        host:
        pkgs.runCommandLocal "caddyfile-${host}" { } ''
          ${lib.getExe config.packages.caddy-extended} adapt \
            --config ${self.nixosConfigurations.${host}.config.services.caddy.configFile} \
            --adapter caddyfile \
            > $out
        '';
    in
    {
      # Library tests are registered by modules/tests/**.nix.
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
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        # Adapt each host's rendered Caddyfile. eta's Caddyfile is formatted
        # by its own aarch64 caddy, so it is adapted with the x86_64 one.
        caddyfile-epsilon = caddyfile "epsilon";
        caddyfile-eta = caddyfile "eta";
        caddyfile-delta = caddyfile "delta";
      };
    };
}
