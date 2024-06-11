{ inputs, ... }: {
  flake.homeConfigurations.limitless = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };

    extraSpecialArgs.inputs = inputs;
    modules = [
      ../home/hosts/limitless
      inputs.stylix.nixosModules.stylix
    ];
  };
}

