{inputs, ...}: {
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    warn-dirty = false;
    experimental-features = ["nix-command" "flakes"];
  };

  system.autoUpgrade = {
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
}
