{
  perSystem =
    { pkgs, lib, ... }:
    let
      # caddy-l4 is pinned past v0.1.2 for the health-check dial-port fix.
      withPlugins =
        caddy:
        caddy.withPlugins {
          plugins = [
            "github.com/mholt/caddy-l4@v0.1.3-0.20261014154252-65c1d329a166"
            "github.com/mholt/caddy-ratelimit@v0.1.0"
          ];

          hash = "sha256-MsuyPulOdzPkTCoxIqVAKOm2t/p70U5EUt3SA6SPqA4=";
        };
    in
    {
      packages = {
        caddy-extended = withPlugins pkgs.caddy;
      }
      // lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
        # A native cross toolchain beats binfmt QEMU.
        caddy-extended-aarch64 = withPlugins pkgs.pkgsCross.aarch64-multiplatform.caddy;
      };
    };
}
