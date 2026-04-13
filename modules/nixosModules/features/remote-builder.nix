{inputs, ...}: {
  flake.nixosModules.remoteBuilder = {config, ...}: {
    nix = {
      distributedBuilds = true;

      buildMachines = [
        {
          # Build directly on lambda over Tailscale, not through eta.
          hostName = "lambda";
          system = "x86_64-linux";
          maxJobs = 32;
          speedFactor = 2;
          protocol = "ssh-ng";
          sshUser = "builder";
          sshKey = config.sops.secrets."builder-ssh-private-key".path;

          supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
          mandatoryFeatures = [];
        }
      ];

      settings = {
        builders-use-substitutes = true;

        # Use eta's HTTPS cache, which mirrors lambda's store.
        substituters = [
          "https://internal.asmussen.tech/"
        ];

        trusted-public-keys = [
          inputs.nix-secrets.hosts.lambda.cache-public-key
        ];
      };
    };

    programs.ssh.knownHosts."builder" = {
      hostNames = ["lambda"];
      publicKey = inputs.nix-secrets.hosts.lambda.ssh-public-key;
    };

    sops.secrets."builder-ssh-private-key" = {};
  };
}
