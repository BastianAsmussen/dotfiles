{inputs, ...}: {
  flake.nixosModules.remoteBuilder = {config, ...}: {
    nix = {
      distributedBuilds = true;

      buildMachines = [
        {
          # Connect to lambda directly over Tailscale for builds.  The
          # public DNS (internal.asmussen.tech) now points to eta which
          # is not a build machine.
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

        # The HTTPS cache at internal.asmussen.tech is served by eta
        # and mirrors lambda's nix store.
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
