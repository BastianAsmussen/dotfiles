{
  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];
      extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
      extra-substituters = "https://devenv.cachix.org";
      warn-dirty = false;
      auto-optimise-store = true;
      http-connections = 64;
      log-lines = 64;
    };

    optimise.automatic = true;
  };
}
