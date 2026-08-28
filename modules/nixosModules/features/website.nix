{ inputs, withSystem, ... }:
{
  flake.nixosModules.website =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # epsilon (x86_64) builds every host's closure, so an aarch64 target
      # builds this Go binary under binfmt QEMU. Re-instantiating the upstream
      # derivation through pkgsCross emits the same aarch64 output from a
      # native toolchain instead.
      crossPackage = withSystem "x86_64-linux" (
        { pkgs, ... }:
        (pkgs.pkgsCross.aarch64-multiplatform.extend inputs.gomod2nix.overlays.default).callPackage
          "${inputs.website}/default.nix"
          { }
      );
    in
    {
      options.website-extras.exposePublicly = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to expose the website through an nginx reverse proxy with HTTPS.
          Set to false when the host handles TLS termination separately (e.g. stream passthrough fallback).
        '';
      };

      imports = [ inputs.website.nixosModules.default ];

      config = {
        services.website = {
          enable = true;
          port = lib.mkDefault 8080;
        };

        services.website.package = lib.mkIf (
          pkgs.stdenv.hostPlatform.system == "aarch64-linux"
        ) crossPackage;

        nginx.reverseProxies.website = lib.mkIf config.website-extras.exposePublicly {
          enable = true;
          domain = "asmussen.tech";
          location = "/";
          upstream = "http://localhost:${toString config.services.website.port}/";
          ssl = {
            dnsProvider = "cloudflare";
            environmentFile = config.sops.templates."cloudflare-acme-env".path;
          };
        };
      };
    };
}
