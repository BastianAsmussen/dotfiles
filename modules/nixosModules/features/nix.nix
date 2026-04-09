{inputs, ...}: {
  flake.nixosModules.nix = {
    lib,
    pkgs,
    config,
    outputs,
    ...
  }: {
    imports = [inputs.determinate.nixosModules.default];

    config = {
      nix = let
        inherit (lib.custom.units) mibToBytes;

        flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
      in {
        # Map flake registry and Nix path to the flake inputs.
        registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
        nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

        # Disable channels.
        channel.enable = false;

        nrBuildUsers = 64;
        settings = {
          experimental-features = [
            "flakes"
            "nix-command"
            "cgroups"
            "auto-allocate-uids"
          ];

          trusted-users = ["root" "@wheel"];
          trusted-substituters = config.nix.settings.substituters;

          http-connections = 32;
          connect-timeout = 5;
          stalled-download-timeout = 30;
          max-jobs = "auto";
          cores = 0;
          eval-cores = 0;
          auto-optimise-store = true;
          builders-use-substitutes = true;
          fallback = true;
          keep-going = true;
          keep-derivations = true;
          keep-outputs = true;
          keep-failed = true;
          warn-dirty = false;
          accept-flake-config = false;
          use-cgroups = pkgs.stdenv.isLinux;
          min-free = mibToBytes 128;
          max-free = mibToBytes 1024;

          # Always build in a sandbox.
          sandbox = true;
          sandbox-fallback = false;

          # Disable the global registry.
          flake-registry = "";
        };
      };

      system.activationScripts.diff = {
        supportsDryActivation = true;
        text = ''
          ${lib.getExe pkgs.nvd} --nix-bin-dir=${config.nix.package}/bin diff /run/current-system "$systemConfig"
        '';
      };

      nixpkgs = {
        overlays = builtins.attrValues outputs.overlays;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };

      environment = {
        etc."determinate/config.json".text = builtins.toJSON {
          garbageCollector.strategy = "disabled";
        };

        # Disable telemetry.
        variables.DETSYS_IDS_TELEMETRY = "disabled";
      };

      systemd = {
        oomd = {
          enable = lib.mkDefault true;

          enableRootSlice = true;
          enableSystemSlice = true;
          enableUserSlices = true;

          settings.OOM."DefaultMemoryPressureDurationSec" = "20s";
        };

        services.nix-daemon = {
          serviceConfig = {
            OOMScoreAdjust = 500;
            MemoryAccounting = true;
            MemoryMax = "90%";
          };

          # Move build directory from /tmp to /var/tmp.
          environment.TMPDIR = "/var/tmp";
        };
      };

      programs.nix-ld.enable = true;
    };
  };
}
