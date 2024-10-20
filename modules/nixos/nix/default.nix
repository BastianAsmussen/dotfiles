{pkgs, ...}: {
  imports = [
    ./nh.nix
  ];

  nix = {
    package = pkgs.lix;

    settings = {
      experimental-features = ["nix-command" "flakes" "recursive-nix" "ca-derivations"];
      trusted-users = ["root" "@wheel"];

      extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
      extra-substituters = "https://devenv.cachix.org";
      flake-registry = "/etc/nix/registry.json";

      max-jobs = "auto";
      warn-dirty = false;
      auto-optimise-store = true;
      builders-use-substitutes = true;
      keep-going = true;
      keep-outputs = true;
      keep-derivations = true;
      accept-flake-config = true;
      commit-lockfile-summary = "chore: update flake.lock";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # Don't build on tmpfs, it's not a good idea.
  systemd.services.nix-daemon = {
    environment.TMPDIR = "/var/tmp";
  };

  # Use the Rust rewrite of `switch` instead of the original one.
  system.switch = {
    enable = false;
    enableNg = true;
  };
}
