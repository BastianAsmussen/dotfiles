{self, ...}: {
  flake.nixosModules.base = {
    lib,
    pkgs,
    ...
  }: {
    documentation.dev.enable = true;

    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    system = {
      configurationRevision = toString (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown");
      stateVersion = lib.mkDefault "26.05";
    };
  };
}
