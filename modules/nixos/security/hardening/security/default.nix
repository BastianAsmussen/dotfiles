{pkgs, ...}: {
  imports = [
    ./audit.nix
  ];

  security = {
    apparmor = {
      enable = true;

      killUnconfinedConfinables = true;
      packages = [pkgs.apparmor-profiles];
    };

    protectKernelImage = true;
    forcePageTableIsolation = true;
    polkit.enable = true;
    rtkit.enable = true;
  };

  systemd.package = pkgs.systemd.override {
    withSelinux = true;
  };
}
