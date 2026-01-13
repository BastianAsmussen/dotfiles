{
  inputs,
  userInfo,
  lib,
  ...
}: let
  inherit (lib) mkForce;
in {
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

  # Running VSCode Remote.
  programs.nix-ld.enable = true;

  # Disable default options as they're rendered redundant in a WSL environment.
  btrfs.enable = false;
  network-manager.enable = false;
  qemu.enable = false;
  vpn.enable = false;

  security.auditd.enable = mkForce false;

  # Used for resolving hostnames.
  services.resolved.enable = true;

  virtualisation.docker = {
    # Enable Docker on boot.
    enableOnBoot = true;

    # Disable btrfs storage driver.
    storageDriver = mkForce null;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
