{ inputs, self, ... }:
{
  imports = [
    inputs.nixvim.flakeModules.default
  ];

  nixvim = {
    packages.enable = true;
    checks.enable = true;
  };

  flake.nixvimModules = {
    default = {
      imports = [
        ./homeManagerModules/_nixvim-config.nix
      ];
    };
  };

  perSystem =
    {
      system,
      pkgs,
      ...
    }:
    {
      nixvimConfigurations = {
        default = inputs.nixvim.lib.evalNixvim {
          inherit system;

          modules = [
            { nixpkgs.pkgs = pkgs; }
            self.nixvimModules.default
          ];
        };
      };
    };
}
