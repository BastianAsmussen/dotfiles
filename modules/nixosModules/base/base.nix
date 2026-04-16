{self, ...}: {
  flake.nixosModules.base = {lib, ...}: {
    documentation = {
      dev.enable = true;
      man.cache.enable = false;
    };

    system = {
      configurationRevision = toString (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown");
      stateVersion = lib.mkDefault "26.05";
    };
  };
}
