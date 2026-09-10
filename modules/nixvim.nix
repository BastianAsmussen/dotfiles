{ inputs, self, ... }:
{
  imports = [
    inputs.nixvim.flakeModules.default
  ];

  nixvim = {
    packages.enable = true;
    checks.enable = true;
  };

  # Every sibling module under nixvimModules/ registers itself; `default` is
  # just the whole set, and is what every consumer imports.
  flake.nixvimModules.default = {
    imports = [
      self.nixvimModules.settings
      self.nixvimModules.autocmds
      self.nixvimModules.clipboard
      self.nixvimModules.theme
      self.nixvimModules.keymaps
      self.nixvimModules.completion
      self.nixvimModules.lsp
      self.nixvimModules.debugging
      self.nixvimModules.telescope
      self.nixvimModules.ui
      self.nixvimModules.editing
      self.nixvimModules.extra-plugins
    ];
  };

  perSystem =
    { system, pkgs, ... }:
    {
      nixvimConfigurations = {
        default = inputs.nixvim.lib.evalNixvim {
          inherit system;

          modules = [
            # The claude-code plugin needs the unfree claude-code CLI; the
            # perSystem pkgs already allows it.
            { nixpkgs.pkgs = pkgs; }
            self.nixvimModules.default
          ];
        };
      };
    };
}
