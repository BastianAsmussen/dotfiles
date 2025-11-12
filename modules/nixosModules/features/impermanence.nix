{self, ...}: {
  flake.nixosModules.impermanence = {config, ...}: {
    imports = [
      self.nixosModules.extra_impermanence
    ];

    persistence = {
      enable = true;

      nukeRoot.enable = true;
      user = config.preferences.user.name;
    };
  };
}
