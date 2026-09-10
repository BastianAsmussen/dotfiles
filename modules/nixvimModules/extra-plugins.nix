{
  # Plugins with no nixvim module of their own.
  flake.nixvimModules.extra-plugins =
    { pkgs, ... }:
    {
      extraPlugins = [
        pkgs.vimPlugins.cellular-automaton-nvim
        (pkgs.vimUtils.buildVimPlugin {
          name = "tuxedo-nvim";
          src = pkgs.fetchFromGitHub {
            owner = "IogaMaster";
            repo = "tuxedo.nvim";
            rev = "65650b0ae3b1c3755a43306b07ada13bd78d47ac";
            hash = "sha256-e8Vk2QvMNDDpYCiTWwm5IgDlDhVKj2g+kNHpLbkYGx4=";
          };
        })
      ];
    };
}
