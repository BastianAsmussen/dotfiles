{
  pkgs,
  lib,
  inputs,
  config,
  ...
}: let
  mibToB = mib: mib * 1024 * 1024;
in {
  imports = [
    ./nh.nix
  ];

  nix = {
    package = pkgs.lix;

    # Add each flake input as a registry.
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    # Add inputs to the system's legacy channels.
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      experimental-features = ["nix-command" "flakes" "recursive-nix" "ca-derivations"];
      trusted-users = ["root" "@wheel"];
      flake-registry = "/etc/nix/registry.json";

      connect-timeout = 5; # Timeout after 5 seconds.
      max-jobs = "auto";
      auto-optimise-store = true;
      builders-use-substitutes = true;
      fallback = true; # Fallback to building from source if binary substitute fails.
      keep-going = true;
      keep-outputs = true;
      keep-derivations = true;
      accept-flake-config = true;
      warn-dirty = false;
      commit-lockfile-summary = "chore: update flake.lock";
      min-free = mibToB 128;
      max-free = mibToB 1024;

      extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
      extra-substituters = "https://devenv.cachix.org";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # Don't build on tmpfs, it's not a good idea.
  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";

  # Use the Rust rewrite of `switch` instead of the original one.
  system.switch = {
    enable = false;
    enableNg = true;
  };
}
