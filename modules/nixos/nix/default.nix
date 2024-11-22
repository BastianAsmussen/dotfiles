{
  pkgs,
  lib,
  inputs,
  outputs,
  ...
}: let
  mibToBytes = mib: mib * 1024 * 1024;
in {
  imports = [
    ./nh.nix
  ];

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    package = pkgs.lix;

    # Map flake registry and Nix path to the flake inputs.
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "recursive-nix"
        "ca-derivations"
      ];

      trusted-users = ["root" "@wheel"];
      connect-timeout = 5; # Timeout after 5 seconds.
      cores = 0;
      auto-optimise-store = true;
      builders-use-substitutes = true;
      fallback = true; # Fallback to building from source if binary substitute fails.
      keep-going = true;
      keep-outputs = true;
      show-trace = true;
      warn-dirty = false;
      min-free = mibToBytes 128;
      max-free = mibToBytes 1024;
    };
  };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config.allowUnfree = true;
  };

  # Move build directory from /tmp to /var/tmp.
  # Source: https://discourse.nixos.org/t/how-do-you-optimize-your-tmp/51956/3
  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";
}
