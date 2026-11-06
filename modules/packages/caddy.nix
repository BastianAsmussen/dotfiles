{
  perSystem =
    { pkgs, lib, ... }:
    let
      # Layer 4 routing for eta's SNI passthrough, rate limiting for epsilon.
      # caddy-l4 is pinned past v0.1.2: its active health check rewrote the
      # upstream's dial port to health_port, so passthrough hit the probe
      # socket instead of the real listener (fixed in mholt/caddy-l4#458).
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
        # epsilon builds eta's closure; a native cross toolchain beats binfmt QEMU.
        caddy-extended-aarch64 = withPlugins pkgs.pkgsCross.aarch64-multiplatform.caddy;
      };
    };
}
