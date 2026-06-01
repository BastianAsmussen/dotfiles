{ inputs, ... }:
{
  flake.nixosModules.winapps =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.winapps;
      user = config.preferences.user.name;
      home = "/home/${user}";
    in
    {
      options.winapps = {
        enable = lib.mkEnableOption "WinApps Windows application integration via Podman";

        windowsVersion = lib.mkOption {
          type = lib.types.str;
          default = "10";
          description = "Windows version passed to the dockur/windows container (e.g. \"10\", \"11\", \"2022\").";
        };

        ramSize = lib.mkOption {
          type = lib.types.str;
          default = "8G";
          description = "RAM allocated to the Windows VM.";
        };

        cpuCores = lib.mkOption {
          type = lib.types.int;
          default = 4;
          description = "CPU cores allocated to the Windows VM.";
        };

        diskSize = lib.mkOption {
          type = lib.types.str;
          default = "64G";
          description = "Disk image size for the Windows VM.";
        };

        rdpScale = lib.mkOption {
          type = lib.types.enum [
            100
            140
            180
          ];

          default = 100;
          description = "RDP display scaling percentage.";
        };

        sharedDir = lib.mkOption {
          type = lib.types.str;
          defaultText = lib.literalExpression ''"~/Windows"'';
          description = "Full path to the host directory mounted into the Windows VM as a shared drive. Never point this at your home root.";
        };
      };

      config = lib.mkIf cfg.enable {
        winapps.sharedDir = lib.mkDefault "${home}/Windows";

        # Required for container folder sharing / NAT.
        boot.kernelModules = [
          "ip_tables"
          "iptable_nat"
        ];

        users.users.${user}.extraGroups = [ "kvm" ];

        systemd.tmpfiles.rules = [
          "d ${cfg.sharedDir} 0750 ${user} ${user} -"
        ];

        programs.zsh.shellAliases =
          let
            compose = "podman-compose -f ${home}/.config/winapps/compose.yaml";
          in
          {
            win-start = "${compose} start";
            win-stop = "${compose} stop";
            win-restart = "${compose} restart";
            win-status = "podman ps --filter name=WinApps --format 'table {{.Names}}\t{{.Status}}'";
          };

        environment.systemPackages = [
          inputs.winapps.packages.${pkgs.stdenv.hostPlatform.system}.winapps
          inputs.winapps.packages.${pkgs.stdenv.hostPlatform.system}.winapps-launcher
          pkgs.freerdp
          pkgs.podman-compose
        ];

        sops = {
          secrets."winapps/rdp-user" = { };
          secrets."winapps/rdp-pass" = { };

          templates."winapps.conf" = {
            owner = user;
            mode = "0600";
            path = "${home}/.config/winapps/winapps.conf";
            content = ''
              RDP_USER="${config.sops.placeholder."winapps/rdp-user"}"
              RDP_PASS="${config.sops.placeholder."winapps/rdp-pass"}"
              RDP_IP="127.0.0.1"
              WAFLAVOR="podman"
              RDP_SCALE=${toString cfg.rdpScale}
              AUTOPAUSE="on"
              AUTOPAUSE_TIME=300
              DEBUG="false"
            '';
          };

          templates."winapps-compose.yaml" = {
            owner = user;
            mode = "0600";
            path = "${home}/.config/winapps/compose.yaml";
            content = ''
              name: "winapps"
              volumes:
                data:
              services:
                windows:
                  image: ghcr.io/dockur/windows:latest
                  container_name: WinApps
                  environment:
                    VERSION: "${cfg.windowsVersion}"
                    RAM_SIZE: "${cfg.ramSize}"
                    CPU_CORES: "${toString cfg.cpuCores}"
                    DISK_SIZE: "${cfg.diskSize}"
                    USERNAME: "${config.sops.placeholder."winapps/rdp-user"}"
                    PASSWORD: "${config.sops.placeholder."winapps/rdp-pass"}"
                  ports:
                    - "127.0.0.1:8006:8006"
                    - "127.0.0.1:3389:3389/tcp"
                    - "127.0.0.1:3389:3389/udp"
                  cap_add:
                    - NET_ADMIN
                  stop_grace_period: 120s
                  restart: on-failure
                  volumes:
                    - data:/storage
                    - ${cfg.sharedDir}:/shared
                  devices:
                    - /dev/kvm
                    - /dev/net/tun
                  group_add:
                    - keep-groups
            '';
          };
        };
      };
    };
}
