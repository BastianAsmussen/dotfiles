{ inputs, self, ... }:
{
  imports = [
    inputs.nixvim.flakeModules.default
  ];

  nixvim = {
    packages.enable = true;
    checks.enable = true;
  };

  # The default nixvim module imports every sibling module.
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
            # Use the unfree-enabled pkgs for the claude-code plugin.
            { nixpkgs.pkgs = pkgs; }
            self.nixvimModules.default
          ];
        };
      };
    };
}
