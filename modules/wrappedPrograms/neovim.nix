{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.neovim = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;

      package = pkgs.neovim;
      runtimeInputs = with pkgs; [
        clang
        gcc
        pkg-config
        manix
        statix
        nixd
        alejandra
        lua-language-server
      ];

      env.SHELL = "zsh";
    };
  };
}
