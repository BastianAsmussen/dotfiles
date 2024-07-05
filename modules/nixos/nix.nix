{inputs, ...}: {
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      warn-dirty = false;
      experimental-features = ["nix-command" "flakes"];
    };

    gc = {
      automatic = true;
      persistent = false;
      dates = "daily";
      options = "--delete-older-than 30d";
    };
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
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
