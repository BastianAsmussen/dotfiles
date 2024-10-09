{pkgs, ...}: {
  imports = [
    ./nh.nix
  ];

  nix = {
    package = pkgs.lix;

    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];

      extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
      extra-substituters = "https://devenv.cachix.org";

      warn-dirty = false;
      auto-optimise-store = true;
      builders-use-substitutes = true;

      keep-outputs = true;
      keep-derivations = true;
    };
  };

  nixpkgs.config.allowUnfree = true;
}
