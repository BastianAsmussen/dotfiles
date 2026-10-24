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
      # Reuse x86_64 map geometry on aarch64; the data bytes are identical.
      mapStatic =
        if config.covenant-extras.includeMap then
          inputs.covenant.packages.x86_64-linux.map-static
        else
          null;

      # Cross-compile from x86_64 instead of running the crate build under QEMU.
      crossPackage = withSystem "x86_64-linux" (
        { pkgs, ... }:
        (pkgs.pkgsCross.aarch64-multiplatform.extend inputs.covenant.overlays.default).covenant.override {
          inherit mapStatic;
        }
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
          smtp = {
            host = "smtp.protonmail.ch";
            port = 587;
            user = "contact@asmussen.tech";
            from = "contact@asmussen.tech";
            to = "contact@asmussen.tech";
            passwordFile = config.sops.secrets."covenant/smtp-token".path;
          };
        };

        # Apply the map override to native and cross builds.
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
