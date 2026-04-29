{
  flake.nixosModules.mtls = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkOption mkEnableOption mkIf types;

    cfg = config.mtls;
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
          description = "SSH public key files allowed to request certificates.";
        };

        caCertPath = mkOption {
          type = types.path;
          description = "Path to the CA certificate (from keys/).";
        };
      };

      client = {
        enable = mkEnableOption "Ephemeral mTLS client certificate renewal";

        signerHost = mkOption {
          type = types.str;
          default = "10.10.0.2";
          description = "SSH host of the mTLS signer (epsilon WG IP).";
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

        sshKeyFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Path to an SSH private key file for authenticating to the signer.
            When null (default), SSH uses gpg-agent (YubiKey).
          '';
        };

        user = mkOption {
          type = types.str;
          description = ''
            User to run the renewal service as. Must have access to the SSH
            authentication method (e.g. gpg-agent for YubiKey).
          '';
        };
      };
    };

    config = lib.mkMerge [
      (mkIf cfg.signer.enable (let
        signScript = pkgs.writeShellScript "mtls-sign" ''
          set -euo pipefail

          CA_KEY="${config.sops.secrets.${cfg.signer.caKeySecret}.path}"
          CA_CERT="${cfg.signer.caCertPath}"
          LIFETIME_HOURS="${toString cfg.signer.certLifetimeHours}"

          WORK=$(mktemp -d)
          trap 'rm -rf "$WORK"' EXIT

          # Read CSR from stdin.
          cat > "$WORK/request.csr"

          if ! ${lib.getExe' pkgs.openssl "openssl"} req -in "$WORK/request.csr" -noout -verify 2>/dev/null; then
            echo "error: invalid CSR" >&2
            exit 1
          fi

          # Extract the requested CN to build SAN (for server certs).
          CN=$(${lib.getExe' pkgs.openssl "openssl"} req -in "$WORK/request.csr" -noout -subject \
            | sed -n 's/.*CN = \(.*\)/\1/p')

          # Sign it.
          ${lib.getExe' pkgs.openssl "openssl"} x509 -req \
            -in "$WORK/request.csr" \
            -CA "$CA_CERT" \
            -CAkey "$CA_KEY" \
            -CAcreateserial \
            -days 1 \
            -extfile <(printf "subjectAltName=DNS:%s" "$CN") \
            2>/dev/null

          # Cert goes to stdout.
        '';
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

      (mkIf cfg.client.enable (let
        renewScript = pkgs.writeShellScript "mtls-renew" ''
          set -euo pipefail

          SIGNER="${cfg.client.signerHost}"
          DIR="/run/mtls"
          SSH_OPTS="-o StrictHostKeyChecking=accept-new -o BatchMode=yes"
          ${lib.optionalString (cfg.client.sshKeyFile != null) ''
            SSH_OPTS="$SSH_OPTS -i ${cfg.client.sshKeyFile}"
          ''}

          # Ensure group (nginx) can read but others cannot.
          umask 027
          mkdir -p "$DIR"

          openssl ecparam -genkey -name prime256v1 \
            -out "$DIR/client.key" 2>/dev/null
          openssl req -new \
            -key "$DIR/client.key" \
            -subj "/CN=${config.networking.hostName}" \
            -out "$DIR/client.csr" 2>/dev/null

          ssh $SSH_OPTS mtls-signer@"$SIGNER" < "$DIR/client.csr" > "$DIR/client.crt"

          ${lib.concatMapStringsSep "\n" (domain: ''
              # ── Local server cert: ${domain} ──
              openssl ecparam -genkey -name prime256v1 \
                -out "$DIR/local-${domain}.key" 2>/dev/null
              openssl req -new \
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
        # Trust the CA so browsers accept local nginx certs.
        security.pki.certificateFiles = [cfg.client.caCertPath];

        # Firefox: honor system trust store.
        programs.firefox.policies.Certificates.ImportEnterpriseRoots = true;

        systemd = {
          tmpfiles.rules = [
            "d /run/mtls 0750 ${cfg.client.user} nginx -"
          ];

          services.mtls-renew = {
            description = "Renew ephemeral mTLS certificates";
            after = ["network-online.target" "wireguard-wg0.service"];
            wants = ["network-online.target"];
            before = ["nginx.service"];
            wantedBy = ["multi-user.target"];

            path = [pkgs.openssh pkgs.openssl];

            # Run as the user who owns the YubiKey / gpg-agent.
            serviceConfig = {
              Type = "oneshot";
              User = cfg.client.user;
              Group = "nginx";
              ExecStart = renewScript;
              # '+' prefix: run as root regardless of User=/Group= above.
              ExecStartPost = "+${lib.getExe' pkgs.systemd "systemctl"} reload-or-restart nginx.service";
              Restart = "on-failure";
              RestartSec = "30s";
            };

            # Point SSH at gpg-agent's socket for YubiKey auth.
            environment.SSH_AUTH_SOCK = "/run/user/${
              toString config.users.users.${cfg.client.user}.uid
            }/gnupg/S.gpg-agent.ssh";
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
