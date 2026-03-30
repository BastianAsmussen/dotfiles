{self, ...}: {
  flake.nixosModules.base = {lib, ...}: {
    documentation.dev.enable = true;

    system = {
      configurationRevision = toString (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown");
      stateVersion = lib.mkDefault "26.05";
    };
  };
}
