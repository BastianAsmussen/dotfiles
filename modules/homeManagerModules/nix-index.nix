{inputs, ...}: {
  flake.homeModules.nixIndex = {
    imports = [
      inputs.nix-index-database.homeModules.nix-index
    ];

    programs = {
      nix-index = {
        enable = true;
        enableZshIntegration = true;
      };

      nix-index-database.comma.enable = true;
    };
  };
}
