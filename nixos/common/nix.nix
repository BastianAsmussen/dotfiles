{
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = "nix-command flakes";

      max-jobs = "auto";
      http-connections = 128;

      max-substitution-jobs = 128;

      # The number of lines of the tail of the log to show if a build fails.
      log-lines = 25;

      # When free disk space in /nix/store drops below min-free during a build, Nix performs a
      # garbage-collection until max-free bytes are available or there is no more garbage.
      min-free = 128000000; # 128 MB
      max-free = 1000000000; # 1 GB

      auto-optimise-store = true;

      warn-dirty = false;

      connect-timeout = 5;
      builders-use-substitutes = true;

      fallback = true;
      substituters = [
        "https://cache.nixos.org"
        "https://cuda-maintainers.cachix.org"
        "https://nix-community.cachix.org"
      ];

      trusted-users = ["root" "bastian"];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 2d";
    };
  };
}
