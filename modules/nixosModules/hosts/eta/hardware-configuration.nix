{
  flake.nixosModules.hostEta = {
    modulesPath,
    lib,
    ...
  }: {
    imports = [
      (modulesPath + "/profiles/qemu-guest.nix")
    ];

    boot = {
      initrd = {
        availableKernelModules = ["xhci_pci" "virtio_pci" "virtio_scsi" "virtio_net" "usbhid" "sr_mod"];
        kernelModules = [];
        luks.forceLuksSupportInInitrd = true;
        systemd.network = {
          enable = true;
          networks."10-eth" = {
            matchConfig.Type = "ether";
            networkConfig = {
              DHCP = "ipv4";
              IPv6AcceptRA = true;
            };
          };
        };

        network = {
          enable = true;
          flushBeforeStage2 = true;
          ssh = {
            enable = true;
            port = 2222;
            hostKeys = ["/boot/initrd-host-key"];
            authorizedKeys =
              # Prompt to unlock encrypted partitions.
              map (k: "command=\"systemd-tty-ask-password-agent\" ${k}")
              (lib.custom.keys.selectSshContents ["ssh-delta.pub" "ssh-epsilon.pub"] lib.custom.keys.default);
          };
        };
      };

      kernelModules = [];
      extraModulePackages = [];
    };

    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  };
}
