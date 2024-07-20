{inputs, ...}: {
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];

      warn-dirty = false;
      auto-optimise-store = true;
      sandbox = "relaxed";

      http-connections = 64;
      log-lines = 64;
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
      dates = "weekly";
    };

    optimise.automatic = true;
  };

  system = {
    stateVersion = "24.05";

    autoUpgrade = {
      enable = true;
      flake = inputs.self.outPath;
      flags = [
        "--update-input"
        "nixpkgs"
        "-L" # Print build logs.
      ];
      dates = "weekly";
      randomizedDelaySec = "45min";
    };
  };
}
