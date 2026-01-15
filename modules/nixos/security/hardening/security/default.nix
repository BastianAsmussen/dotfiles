{pkgs, ...}: {
  imports = [
    # ./audit.nix
  ];

  security = {
    apparmor = {
      enable = true;

      enableCache = true;
      killUnconfinedConfinables = true;
      packages = [pkgs.apparmor-profiles];
    };

    protectKernelImage = true;
    forcePageTableIsolation = true;
    polkit.enable = true;
    rtkit.enable = true;

    # Always flush L1 cache before entering a guest.
    virtualisation.flushL1DataCache = "always";
  };
}
