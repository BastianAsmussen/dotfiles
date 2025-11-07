{
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      NIX_CONFIG = "experimental-features = nix-command flakes";

      packages = with pkgs; [
        git
        fzf
        lix

        # Code Linting.
        statix
        deadnix
        alejandra
        flake-checker
      ];
    };
  };
}
