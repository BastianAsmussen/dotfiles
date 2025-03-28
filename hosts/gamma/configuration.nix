{
  inputs,
  userInfo,
  lib,
  ...
}: {
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];

  wsl = {
    enable = true;

    defaultUser = userInfo.username;
    wslConf = {
      automount.root = "/mnt";
      interop.appendWindowsPath = false;
      network = {
        generateHosts = false;
        generateResolvConf = false;
      };
    };

    startMenuLaunchers = true;
    docker-desktop.enable = false;
  };

  # Disable default options as they're rendered redundant in a WSL environment.
  btrfs.enable = false;
  network-manager.enable = false;
  qemu.enable = false;
  vpn.enable = false;

  # Used for resolving hostnames.
  services.resolved.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
