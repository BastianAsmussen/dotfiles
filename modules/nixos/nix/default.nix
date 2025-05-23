{
  lib,
  config,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports = [
    ./binary-cache.nix
    ./nh.nix
  ];

  options.nix.remoteBuilder.enable = lib.mkEnableOption "Marks this machine as a remote builder.";

  config = {
    nix = let
      inherit (lib.custom.units) mibToBytes;

      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in {
      package = pkgs.lix;

      # Map flake registry and Nix path to the flake inputs.
      registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

      # Disable channels.
      channel.enable = false;

      # Enable build distribution.
      distributedBuilds = true;

      nrBuildUsers = lib.mkIf config.nix.remoteBuilder.enable 64;
      settings = {
        experimental-features = [
          "flakes"
          "nix-command"
          "recursive-nix" # Allow derivation builders to call Nix.
          "ca-derivations" # Enable possible early cutoffs during rebuilds.
          "cgroups" # Allow Nix to execute builds inside cgroups.
          "auto-allocate-uids" # Allow Nix to automatically pick UIDs, rather than creating nixbld* user accounts.
          "dynamic-derivations" # Allow building of .drv files.
          "no-url-literals" # Disallow deprecated url-literals, i.e., URLs without quotation.
        ];

        trusted-users =
          ["root" "@wheel"]
          ++ (lib.optionals config.nix.remoteBuilder.enable [
            "builder"
          ]);

        http-connections = 32;
        connect-timeout = 5; # Timeout after 5 seconds.
        stalled-download-timeout = 30; # Retry downloads if no data is recieived for 20 seconds.
        max-jobs = "auto";
        cores = 0;
        auto-optimise-store = true;
        builders-use-substitutes = true;
        fallback = true; # Fallback to building from source if binary substitute fails.
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

    nixpkgs = {
      overlays = builtins.attrValues outputs.overlays;
      config.allowUnfree = true;
    };

    systemd = {
      # systemd OOMd.
      # Fedora enables these options by default. See the 10-oomd-* files here:
      # https://src.fedoraproject.org/rpms/systemd/tree/3211e4adfcca38dfe24188e28a65b1cf385ecfd6
      # by default it only kills cgroups. So either systemd services marked for
      # killing under OOM or (disabled by default, enabled by us) the entire user
      # slice. Fedora used to kill root and system slices, but their OOMd
      # configuration has since changed.
      oomd = {
        enable = lib.mkDefault true;

        enableRootSlice = true;
        enableSystemSlice = true;
        enableUserSlices = true;

        extraConfig."DefaultMemoryPressureDurationSec" = "20s";
      };

      services.nix-daemon = {
        serviceConfig =
          {
            OOMScoreAdjust = 500;
          }
          // (lib.optionalAttrs config.nix.remoteBuilder.enable {
            MemoryAccounting = true;
            MemoryMax = "90%";
          });

        # Move build directory from /tmp to /var/tmp.
        # Source: https://discourse.nixos.org/t/how-do-you-optimize-your-tmp/51956/3
        environment.TMPDIR = "/var/tmp";
      };
    };

    users = lib.mkIf config.nix.remoteBuilder.enable {
      users.builder = {
        isNormalUser = true;
        createHome = false;
        group = "builder";
        hashedPassword = "*";

        openssh.authorizedKeys.keyFiles = lib.custom.keys.default.builderPaths;
      };

      groups.builder = {};
    };
  };
}
