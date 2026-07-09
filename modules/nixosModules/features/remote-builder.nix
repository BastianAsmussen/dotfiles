{ inputs, ... }:
{
  flake.nixosModules.remoteBuilder =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkOption mkIf types;

      cfg = config.remoteBuilder;
      hostname = config.networking.hostName;
      sshKey = config.sops.secrets."hosts/${hostname}/builder-ssh-private-key".path;

      activeBuildersFile = "/etc/nix/active-builders";
      overrideFile = "/run/builder-override";

      builder-ctl = pkgs.writeShellApplication {
        name = "builder-ctl";
        runtimeInputs = [ pkgs.openssh ];
        text = ''
          usage() {
            echo "Usage: builder-ctl <up|down|auto|status>"
            exit 1
          }

          [ $# -eq 1 ] || usage

          case "$1" in
            up)
              echo up > ${overrideFile}
              cp /etc/nix/machines ${activeBuildersFile}
              echo "Builder forced UP (override persists until reboot or 'builder-ctl auto')"
              ;;
            down)
              echo down > ${overrideFile}
              : > ${activeBuildersFile}
              echo "Builder forced DOWN (override persists until reboot or 'builder-ctl auto')"
              ;;
            auto)
              rm -f ${overrideFile}
              systemctl start check-remote-builder.service
              if [ -s ${activeBuildersFile} ]; then
                echo "Override cleared, probe says builder is UP"
              else
                echo "Override cleared, probe says builder is DOWN"
              fi
              ;;
            status)
              if [ -f ${overrideFile} ]; then
                echo "Override: $(cat ${overrideFile})"
              else
                echo "Override: none (auto)"
              fi
              if [ -s ${activeBuildersFile} ]; then
                echo "Builder: active"
              else
                echo "Builder: inactive"
              fi
              ;;
            *)
              usage
              ;;
          esac
        '';
      };
    in
    {
      options.remoteBuilder = {
        jumpHost = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            SSH hostname or IP to use as a ProxyJump when connecting to the
            build machine.  Required when the build machine is not directly
            reachable from this host.
          '';
        };

        probeInterval = mkOption {
          type = types.str;
          default = "5min";
          description = "How often to probe the remote builder for availability.";
        };
      };

      config = {
        nix = {
          distributedBuilds = true;
          buildMachines = [
            {
              hostName = "10.10.0.2";
              system = "x86_64-linux";
              maxJobs = 32;
              speedFactor = 10;
              protocol = "ssh-ng";
              sshUser = "builder";
              inherit sshKey;

              supportedFeatures = [
                "nixos-test"
                "benchmark"
                "big-parallel"
                "kvm"
              ];
              mandatoryFeatures = [ ];
            }
          ];

          settings = {
            builders-use-substitutes = true;
            builders = lib.mkForce "@${activeBuildersFile}";
          };
        };

        # Seed the active-builders file from the static machines list on every
        # activation.  Optimistic: assumes the builder is up until the probe
        # says otherwise.
        system.activationScripts.active-builders = lib.stringAfter [ "etc" ] ''
          cp /etc/nix/machines ${activeBuildersFile}
        '';

        systemd.services.check-remote-builder = {
          description = "Probe remote build machine availability";
          after = [
            "network-online.target"
            "sops-nix.service"
          ];
          wants = [ "network-online.target" ];
          path = [ pkgs.openssh ];
          serviceConfig.Type = "oneshot";
          script = ''
            if [ -f ${overrideFile} ]; then
              case "$(cat ${overrideFile})" in
                up)   cp /etc/nix/machines ${activeBuildersFile} ;;
                down) : > ${activeBuildersFile} ;;
              esac
              exit 0
            fi

            if ssh -i "${sshKey}" \
                 -o ConnectTimeout=5 \
                 -o BatchMode=yes \
                 builder@10.10.0.2 true 2>/dev/null; then
              cp /etc/nix/machines ${activeBuildersFile}
            else
              : > ${activeBuildersFile}
            fi
          '';
        };

        systemd.timers.check-remote-builder = {
          description = "Periodically probe remote build machine";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "1min";
            OnUnitActiveSec = cfg.probeInterval;
          };
        };

        environment.systemPackages = [ builder-ctl ];

        programs.ssh = {
          knownHosts = {
            "epsilon-wg" = {
              hostNames = [ "10.10.0.2" ];
              publicKey = inputs.nix-secrets.hosts.epsilon.ssh-public-key;
            };
          }
          // lib.optionalAttrs (cfg.jumpHost != null) {
            "eta-public" = {
              hostNames = [ cfg.jumpHost ];
              publicKey = inputs.nix-secrets.hosts.eta.ssh-public-key;
            };
          };

          extraConfig = mkIf (cfg.jumpHost != null) ''
            Host ${cfg.jumpHost}
              User builder
              IdentityFile ${sshKey}
              ConnectTimeout 10

            Host 10.10.0.2
              ProxyJump builder@${cfg.jumpHost}
              ConnectTimeout 10
              ServerAliveInterval 5
              ServerAliveCountMax 3
          '';
        };

        sops.secrets."hosts/${hostname}/builder-ssh-private-key".mode = "0400";
      };
    };
}
