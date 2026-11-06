{ inputs, ... }: {
  flake.nixvimModules.extra-plugins =
    { pkgs, ... }:
    {
      extraPlugins = [
        pkgs.vimPlugins.cellular-automaton-nvim
        (pkgs.vimUtils.buildVimPlugin {
          name = "tuxedo-nvim";
          src = inputs.tuxedo-nvim;
        })
      ];
    };
}
