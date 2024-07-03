{ inputs, ... }: {
  home-manager."bastian" = {
    extraSpecialArgs = {inherit inputs;};
    users.modules = [
      ./home.nix

      inputs.self.outputs.homeManagerModules.default
    ];
  };
}
