{inputs, ...}: {
  flake.nixosModules.remoteBuilder = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkOption mkIf types;

    cfg = config.remoteBuilder;
    hostname = config.networking.hostName;
  in {
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
    };

    config = {
      nix = {
        distributedBuilds = true;

        buildMachines = [
          {
            hostName = "10.10.0.2";
            system = "x86_64-linux";
            maxJobs = 32;
            speedFactor = 2;
            protocol = "ssh-ng";
            sshUser = "builder";
            sshKey = config.sops.secrets."hosts/${hostname}/builder-ssh-private-key".path;

            supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
            mandatoryFeatures = [];
          }
        ];

        settings = {
          builders-use-substitutes = true;

          substituters = [
            "https://cache.asmussen.tech/"
          ];

          trusted-public-keys = [
            inputs.nix-secrets.hosts.epsilon.cache-public-key
            inputs.nix-secrets.hosts.eta.cache-public-key
          ];
        };
      };

      programs.ssh = {
        knownHosts =
          {
            "epsilon-wg" = {
              hostNames = ["10.10.0.2"];
              publicKey = inputs.nix-secrets.hosts.epsilon.ssh-public-key;
            };
          }
          // lib.optionalAttrs (cfg.jumpHost != null) {
            "eta-public" = {
              hostNames = [cfg.jumpHost];
              publicKey = inputs.nix-secrets.hosts.eta.ssh-public-key;
            };
          };

        extraConfig = mkIf (cfg.jumpHost != null) ''
          Host 10.10.0.2
            ProxyJump ${cfg.jumpHost}
        '';
      };

      sops.secrets."hosts/${hostname}/builder-ssh-private-key" = {};
    };
  };
}
