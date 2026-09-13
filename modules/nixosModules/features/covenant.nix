{ inputs, withSystem, ... }:
{
  flake.nixosModules.covenant =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Derived boundary geometry for /map: tiles, metadata and the Article I
      # figure. Taken from x86_64 on every host because it is data rather than
      # code, so an aarch64 host has nothing to gain from running a fifteen
      # minute geometry pass under QEMU to reach the same bytes.
      mapStatic =
        if config.covenant-extras.includeMap then
          inputs.covenant.packages.x86_64-linux.map-static
        else
          null;

      # Same reasoning as features/website.nix: cross from the x86_64 builder
      # rather than compiling Go under binfmt QEMU.
      crossPackage = withSystem "x86_64-linux" (
        { pkgs, ... }:
        (pkgs.pkgsCross.aarch64-multiplatform.extend inputs.gomod2nix.overlays.default).callPackage
          "${inputs.covenant}/default.nix"
          { inherit mapStatic; }
      );

      nativePackage = inputs.covenant.packages.${pkgs.system}.default.override { inherit mapStatic; };
    in
    {
      options.covenant-extras = {
        domain = lib.mkOption {
          type = lib.types.str;
          default = "covenantofearth.org";
          description = ''
            Domain the Covenant is served on.  It deliberately does not live
            under asmussen.tech: the document stands on its own, and the shared
            wildcard certificate therefore does not cover it.
          '';
        };

        includeMap = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to ship the derived boundary geometry that /map draws.

            Building it is a ten to fifteen minute geometry pass over roughly
            620MB of pinned source data, cached like any other derivation once
            built, so the cost falls on the first deploy after the sources
            change and on no other.

            With this off the site is unchanged except that /map returns 404:
            the server treats missing metadata as "no map derived" rather than
            as a failure, so the two documents are never held hostage to the
            geometry.
          '';
        };

        exposePublicly = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Whether to expose the Covenant through an nginx reverse proxy with
            HTTPS.  Off by default because the only host serving it (eta) runs
            nginx in TLS stream-passthrough mode, where a reverse-proxy virtual
            host would fight the stream listener for port 443.  Such a host
            declares its own virtual host on the internal fallback listener and
            routes SNI to it instead.
          '';
        };
      };

      imports = [ inputs.covenant.nixosModules.default ];

      config = {
        services.covenant = {
          enable = true;
          port = lib.mkDefault 8084;
          canonicalURL = "https://${config.covenant-extras.domain}";
        };

        # Set on both paths rather than only the cross one: a native host needs
        # the override too, or it takes the flake's default build, which
        # carries no map.
        services.covenant.package =
          if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then crossPackage else nativePackage;

        nginx.reverseProxies.covenant = lib.mkIf config.covenant-extras.exposePublicly {
          enable = true;

          inherit (config.covenant-extras) domain;

          location = "/";
          upstream = "http://localhost:${toString config.services.covenant.port}/";
          ssl = {
            dnsProvider = "cloudflare";
            environmentFile = config.sops.templates."cloudflare-acme-env".path;
          };
        };
      };
    };
}
