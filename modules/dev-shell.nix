{
  perSystem = {
    pkgs,
    config,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      inherit (config.pre-commit) shellHook;

      inputsFrom = [(import ../shell.nix {inherit pkgs;})];
    };
  };
}
