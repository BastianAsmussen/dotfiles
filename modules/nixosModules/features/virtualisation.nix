{
  flake.nixosModules.virtualisation = {
    lib,
    config,
    pkgs,
    userInfo,
    ...
  }: let
    inherit (lib) mkOption types mkMerge;
  in {
    options.kubernetes.master = mkOption {
      default = {};
      type = types.submodule {
        options = {
          ip = mkOption {
            default = "127.0.0.1";
            description = "The master IP that Kubernetes will use.";
            type = types.str;
          };

          hostname = mkOption {
            default = "api.kube";
            description = "The master hostname that Kubernetes will use.";
            type = types.str;
          };

          apiPort = mkOption {
            default = 6443;
            description = "The master API server port that Kubernetes will use.";
            type = types.int;
          };
        };
      };
    };

    config = let
      cfg = config.kubernetes;
    in
      mkMerge [
        # Android
        {
          environment.systemPackages = [
            pkgs.android-studio
          ];

          programs.java.enable = true;
          users.users.${userInfo.username}.extraGroups = [
            "kvm"
            "adbusers"
          ];
        }

        # Bottles
        {
          environment.systemPackages = [pkgs.bottles];
        }

        # Docker
        {
          virtualisation.docker = {
            enable = true;

            storageDriver = "btrfs";
            autoPrune.enable = true;
          };

          users.extraGroups.docker.members = [userInfo.username];
        }

        # Kubernetes
        {
          networking.extraHosts = "${cfg.master.ip} ${cfg.master.hostname}";
          environment.systemPackages = with pkgs; [
            kompose
            kubectl
            kubernetes
          ];

          services.kubernetes = {
            roles = ["master" "node"];
            masterAddress = cfg.master.hostname;
            apiserverAddress = "https://${cfg.master.hostname}:${toString cfg.master.apiPort}";
            easyCerts = true;
            apiserver = {
              securePort = cfg.master.apiPort;
              advertiseAddress = cfg.master.ip;
            };

            addons.dns.enable = true;
            kubelet.extraOpts = "--fail-swap-on=false";
          };
        }

        # QEMU
        {
          virtualisation.libvirtd.enable = true;
          users.extraGroups.libvirt.members = [userInfo.username];

          boot.binfmt.emulatedSystems = [
            "aarch64-linux"
            "i686-linux"
            "riscv64-linux"
          ];

          programs.virt-manager.enable = true;
        }
      ];
  };
}
