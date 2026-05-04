# GUI application set shared across desktop/laptop hosts.
{self, ...}: {
  flake.homeModules.desktop = {
    imports = with self.homeModules; [
      alacritty
      firefox
      spicetify
      nixcord
      noctalia
    ];
  };
}
