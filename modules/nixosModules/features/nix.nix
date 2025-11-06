{
  inputs,
  lib,
  self,
  ...
}: {
  flake.nixosModules.nix = {pkgs, ...}: {
    imports = [
      inputs.nix-index-database.nixosModules.nix-index
    ];

    programs = {
      nix-index-database.comma.enable = true;
      nix-ld.enable = true;
    };

    nix = let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
      mibToBytes = mib: mib * 1024 * 1024;
    in {
      package = pkgs.lix;

      # Map flake registry and Nix path to the flake inputs.
      registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

      # Disable channels.
      channel.enable = false;

      # Enable build distribution.
      distributedBuilds = true;

      settings = {
        experimental-features = [
          "flakes" # Enable flake support.
          "nix-command" # Enable new Nix commands.
          "cgroups" # Allow Nix to execute builds inside cgroups.
          "auto-allocate-uids" # Allow Nix to automatically pick UIDs, rather than creating nixbld* user accounts.
          "no-url-literals" # Disallow deprecated url-literals, i.e., URLs without quotation.
        ];

        trusted-users = ["root" "@wheel"];
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
      overlays = builtins.attrValues self.outputs.overlays;
      config.allowUnfree = true;
    };

    environment.systemPackages = with pkgs; [
      # Nix tooling.
      nil
      nixd
      statix
      alejandra
      manix
      nix-inspect
    ];
  };
}
