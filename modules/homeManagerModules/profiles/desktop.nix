# GUI application set shared across desktop/laptop hosts.
{self, ...}: {
  flake.homeModules.desktop = {
    imports = with self.homeModules; [
      passwordStore
      alacritty
      firefox
      spicetify
      nixcord
    ];
  };
}
