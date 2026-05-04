{
  flake.nixosModules.mtls = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkOption mkEnableOption mkIf types;

    cfg = config.mtls;

    openssl = lib.getExe' pkgs.openssl "openssl";

    # Shared signing logic: reads a CSR from stdin, writes a signed cert to stdout.
    # Extracted so the local-signer renewal path can call it directly.
    mkSignScript = caKeyPath: caCertPath: lifetimeHours:
      pkgs.writeShellScript "mtls-sign" ''
        set -euo pipefail

        CA_KEY="${caKeyPath}"
        CA_CERT="${caCertPath}"

        WORK=$(mktemp -d)
        trap 'rm -rf "$WORK"' EXIT

        # Read CSR from stdin.
        cat > "$WORK/request.csr"

        if ! ${openssl} req -in "$WORK/request.csr" -noout -verify 2>/dev/null; then
          echo "error: invalid CSR" >&2
          exit 1
        fi

        # Extract the requested CN to build SAN (for server certs).
        CN=$(${openssl} req -in "$WORK/request.csr" -noout -subject \
          | sed -n 's/.*CN = \(.*\)/\1/p')

        # Sign it.
        ${openssl} x509 -req \
          -in "$WORK/request.csr" \
          -CA "$CA_CERT" \
          -CAkey "$CA_KEY" \
          -CAserial "$WORK/ca.srl" -CAcreateserial \
          -days ${toString lifetimeHours} \
          -extfile <(printf "subjectAltName=DNS:%s" "$CN") \
          2>/dev/null

        # Cert goes to stdout.
      '';
  in {
    options.mtls = {
      signer = {
        enable = mkEnableOption "mTLS certificate signing service";

        caKeySecret = mkOption {
          type = types.str;
          default = "mtls/ca-key";
          description = "Sops secret key containing the CA private key PEM.";
        };

        certLifetimeHours = mkOption {
          type = types.ints.positive;
          default = 24;
          description = "Lifetime of issued certificates in hours.";
        };

        authorizedKeyFiles = mkOption {
          type = types.listOf types.path;
          default = [];
          description = "SSH public key files allowed to request certificates.";
        };

        caCertPath = mkOption {
          type = types.path;
          description = "Path to the CA certificate (from keys/).";
        };
      };

      client = {
        enable = mkEnableOption "Ephemeral mTLS client certificate renewal";

        localSigner = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Sign certificates directly using the local CA key instead of SSHing
            to the signer. Only valid when mtls.signer is also enabled on this
            host. Removes the dependency on gpg-agent / YubiKey at boot time.
          '';
        };

        signerHost = mkOption {
          type = types.str;
          default = "10.10.0.2";
          description = "SSH host of the mTLS signer (epsilon WG IP). Ignored when localSigner = true.";
        };

        domains = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Domains to generate local server certs for (with SANs).";
        };

        renewIntervalHours = mkOption {
          type = types.ints.positive;
          default = 12;
          description = "How often to renew certificates.";
        };

        caCertPath = mkOption {
          type = types.path;
          description = "Path to the CA certificate (from keys/).";
        };

        sshKeySecret = mkOption {
          type = types.str;
          default = "hosts/${config.networking.hostName}/mtls-ssh-private-key";
          description = "Sops secret key containing the SSH private key used to authenticate to the signer.";
        };
      };
    };

    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = !cfg.client.localSigner || cfg.signer.enable;
            message = "mtls.client.localSigner requires mtls.signer to also be enabled on this host.";
          }
        ];
      }

      (mkIf cfg.signer.enable (let
        signScript =
          mkSignScript
          config.sops.secrets.${cfg.signer.caKeySecret}.path
          cfg.signer.caCertPath
          cfg.signer.certLifetimeHours;
      in {
        sops.secrets.${cfg.signer.caKeySecret} = {
          owner = "mtls-signer";
          group = "mtls-signer";
        };

        users = {
          users.mtls-signer = {
            isSystemUser = true;
            group = "mtls-signer";
            home = "/var/empty";
            shell = pkgs.shadow;
            openssh.authorizedKeys.keyFiles = cfg.signer.authorizedKeyFiles;
          };
          groups.mtls-signer = {};
        };

        # Force the signing script as the only allowed command.
        services.openssh.extraConfig = ''
          Match User mtls-signer
            ForceCommand ${signScript}
            AllowAgentForwarding no
            AllowTcpForwarding no
            AllowStreamLocalForwarding no
            PermitTTY no
            X11Forwarding no
        '';
      }))

      (mkIf (cfg.client.enable && cfg.client.localSigner) (let
        signScript =
          mkSignScript
          config.sops.secrets.${cfg.signer.caKeySecret}.path
          cfg.client.caCertPath
          cfg.signer.certLifetimeHours;

        renewScript = pkgs.writeShellScript "mtls-renew" ''
          set -euo pipefail

          DIR="/run/mtls"

          # Ensure group (nginx) can read but others cannot.
          umask 027
          mkdir -p "$DIR"

          ${openssl} ecparam -genkey -name prime256v1 \
            -out "$DIR/client.key" 2>/dev/null
          ${openssl} req -new \
            -key "$DIR/client.key" \
            -subj "/CN=${config.networking.hostName}" \
            -out "$DIR/client.csr" 2>/dev/null

          ${signScript} < "$DIR/client.csr" > "$DIR/client.crt"

          ${lib.concatMapStringsSep "\n" (domain: ''
              ${openssl} ecparam -genkey -name prime256v1 \
                -out "$DIR/local-${domain}.key" 2>/dev/null
              ${openssl} req -new \
                -key "$DIR/local-${domain}.key" \
                -subj "/CN=${domain}" \
                -out "$DIR/local-${domain}.csr" 2>/dev/null

              ${signScript} < "$DIR/local-${domain}.csr" > "$DIR/local-${domain}.crt"

              rm -f "$DIR/local-${domain}.csr"
            '')
            cfg.client.domains}

          rm -f "$DIR/client.csr"
        '';
      in {
        # Trust the CA so browsers accept local nginx certs.
        security.pki.certificateFiles = [cfg.client.caCertPath];

        # Firefox: honor system trust store.
        programs.firefox.policies.Certificates.ImportEnterpriseRoots = true;

        systemd = {
          tmpfiles.rules = [
            "d /run/mtls 0750 mtls-signer nginx -"
          ];

          services.mtls-renew = {
            description = "Renew ephemeral mTLS certificates";
            after = ["network-online.target" "wireguard-wg0.service" "sops-nix.service"];
            wants = ["network-online.target"];
            before = ["nginx.service"];
            wantedBy = ["multi-user.target"];

            path = [pkgs.openssl];

            serviceConfig = {
              Type = "oneshot";
              User = "mtls-signer";
              Group = "nginx";
              ExecStart = renewScript;
              # '+' prefix: run as root regardless of User=/Group= above.
              ExecStartPost = "+${lib.getExe' pkgs.systemd "systemctl"} reload-or-restart nginx.service";
              Restart = "on-failure";
              RestartSec = "30s";
            };
          };

          timers.mtls-renew = {
            description = "Periodic mTLS certificate renewal";
            wantedBy = ["timers.target"];
            timerConfig = {
              OnBootSec = "1min";
              OnUnitActiveSec = "${toString cfg.client.renewIntervalHours}h";
              RandomizedDelaySec = "5min";
            };
          };
        };
      }))

      (mkIf (cfg.client.enable && !cfg.client.localSigner) (let
        sshKey = config.sops.secrets.${cfg.client.sshKeySecret}.path;

        renewScript = pkgs.writeShellScript "mtls-renew" ''
          set -euo pipefail

          SIGNER="${cfg.client.signerHost}"
          DIR="/run/mtls"
          SSH_OPTS="-o StrictHostKeyChecking=accept-new -o BatchMode=yes -i ${sshKey}"

          # Ensure group (nginx) can read but others cannot.
          umask 027
          mkdir -p "$DIR"

          ${openssl} ecparam -genkey -name prime256v1 \
            -out "$DIR/client.key" 2>/dev/null
          ${openssl} req -new \
            -key "$DIR/client.key" \
            -subj "/CN=${config.networking.hostName}" \
            -out "$DIR/client.csr" 2>/dev/null

          ssh $SSH_OPTS mtls-signer@"$SIGNER" < "$DIR/client.csr" > "$DIR/client.crt"

          ${lib.concatMapStringsSep "\n" (domain: ''
              ${openssl} ecparam -genkey -name prime256v1 \
                -out "$DIR/local-${domain}.key" 2>/dev/null
              ${openssl} req -new \
                -key "$DIR/local-${domain}.key" \
                -subj "/CN=${domain}" \
                -out "$DIR/local-${domain}.csr" 2>/dev/null

              ssh $SSH_OPTS mtls-signer@"$SIGNER" < "$DIR/local-${domain}.csr" > "$DIR/local-${domain}.crt"

              rm -f "$DIR/local-${domain}.csr"
            '')
            cfg.client.domains}

          rm -f "$DIR/client.csr"
        '';
      in {
        sops.secrets.${cfg.client.sshKeySecret} = {
          owner = "mtls-client";
          group = "mtls-client";
        };

        users = {
          users.mtls-client = {
            isSystemUser = true;
            group = "mtls-client";
            home = "/var/empty";
            shell = pkgs.shadow;
          };
          groups.mtls-client = {};
        };

        # Trust the CA so browsers accept local nginx certs.
        security.pki.certificateFiles = [cfg.client.caCertPath];

        # Firefox: honor system trust store.
        programs.firefox.policies.Certificates.ImportEnterpriseRoots = true;

        systemd = {
          tmpfiles.rules = [
            "d /run/mtls 0750 mtls-client nginx -"
          ];

          services.mtls-renew = {
            description = "Renew ephemeral mTLS certificates";
            after = ["network-online.target" "wireguard-wg0.service" "sops-nix.service"];
            wants = ["network-online.target"];
            before = ["nginx.service"];
            wantedBy = ["multi-user.target"];

            path = [pkgs.openssh pkgs.openssl];

            serviceConfig = {
              Type = "oneshot";
              User = "mtls-client";
              Group = "nginx";
              ExecStart = renewScript;
              # '+' prefix: run as root regardless of User=/Group= above.
              ExecStartPost = "+${lib.getExe' pkgs.systemd "systemctl"} reload-or-restart nginx.service";
              Restart = "on-failure";
              RestartSec = "30s";
            };
          };

          timers.mtls-renew = {
            description = "Periodic mTLS certificate renewal";
            wantedBy = ["timers.target"];
            timerConfig = {
              OnBootSec = "1min";
              OnUnitActiveSec = "${toString cfg.client.renewIntervalHours}h";
              RandomizedDelaySec = "5min";
            };
          };
        };
      }))
    ];
  };
}
