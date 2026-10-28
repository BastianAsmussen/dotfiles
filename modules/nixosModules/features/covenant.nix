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
      # Derived boundary geometry for /map.
      mapStatic =
        if config.covenant-extras.includeMap then
          inputs.covenant.packages.x86_64-linux.map-static
        else
          null;

      # The text, its search vectors and its PDFs, architecture neutral.
      bundle = inputs.covenant.packages.x86_64-linux.bundle;

      crossPackage = withSystem "x86_64-linux" (
        { pkgs, ... }:
        (pkgs.pkgsCross.aarch64-multiplatform.extend inputs.covenant.overlays.default).covenant.override {
          inherit mapStatic bundle;
        }
      );

      nativePackage = inputs.covenant.packages.${pkgs.system}.default.override {
        inherit mapStatic bundle;
      };
    in
    {
      options.covenant-extras = {
        domain = lib.mkOption {
          type = lib.types.str;
          default = "covenantofearth.org";
          description = "Domain the Covenant is served on.";
        };

        includeMap = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to ship the derived boundary geometry that /map draws.

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
          package =
            if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then crossPackage else nativePackage;
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
          environmentFile = config.sops.templates."covenant-env".path;
          content = {
            url = "ssh://git@codeberg.org/BastianA/covenant-text.git";
            deployKeyFile = config.sops.secrets."covenant/deploy-key".path;
          };
          # Built on epsilon while the builder probe finds it up.
          publish = {
            enable = true;
            remoteSystem = "x86_64-linux";
          };
        };

        # The deploy key is only offered to a host this pins.
        programs.ssh.knownHosts.codeberg = {
          hostNames = [ "codeberg.org" ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVIC02vnjFyL+I4RHfvIGNtOgJMe769VTF1VR4EB3ZB";
        };

        # systemd does not expand an EnvironmentFile, so the hash's $ fields stay literal.
        sops.templates."covenant-env" = {
          content = ''
            COVENANT_ADMIN_EMAIL=${config.sops.placeholder."covenant/admin-email"}
            COVENANT_ADMIN_NAME=Bastian Asmussen
            COVENANT_ADMIN_PASSWORD_HASH=${config.sops.placeholder."covenant/admin-password-hash"}
          '';
          restartUnits = [ "covenant.service" ];
        };

        # The site's state, and the published bundle with its build status.
        persistence.directories = [
          "/var/lib/private/covenant"
          "/var/lib/covenant-publish"
        ];

        nginx.reverseProxies.covenant = lib.mkIf config.covenant-extras.exposePublicly {
          inherit (config.covenant-extras) domain;

          enable = true;
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
