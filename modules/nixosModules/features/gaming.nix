{ inputs, ... }:
{
  flake.nixosModules.gaming =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      # Use the CachyOS gaming-focused kernel.
      nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
      boot = {
        kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto.extend (
          _: prev: {
            kernel = prev.kernel.override { stdenv = pkgs.ccacheStdenv; };
          }
        );

        # Expose /dev/ntsync so Wine/Proton can use in-kernel NT synchronization
        # primitives instead of esync/fsync emulation.
        kernelModules = [ "ntsync" ];

        kernel.sysctl = {
          # Keep game working sets in RAM; plenty of headroom before swap matters.
          "vm.swappiness" = 10;

          # Modern games/launchers mmap far beyond the kernel default.
          "vm.max_map_count" = 2147483642;
        };
      };

      programs = {
        steam = {
          enable = true;
          gamescopeSession.enable = true;
          protontricks.enable = true;

          # Unset fcitx5 IM environment variables so Proton games (XWayland)
          # receive keyboard input directly without routing through the IME,
          # which mangles non-Japanese layouts like Danish.
          package = lib.mkIf config.japanese.enable (
            pkgs.steam.overrideAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
              postFixup = (old.postFixup or "") + ''
                wrapProgram $out/bin/steam \
                  --unset XMODIFIERS \
                  --unset GTK_IM_MODULE \
                  --unset QT_IM_MODULE \
                  --unset SDL_IM_MODULE
              '';
            })
          );
        };

        gamemode = {
          enable = true;
          enableRenice = true;

          settings = {
            general = {
              # Only raise clocks/priority while a game is registered, instead
              # of pinning the governor to performance system-wide.
              desiredgov = "performance";
              softrealtime = "auto";
              renice = 10;
              ioprio = 0;
              inhibit_screensaver = 1;
            };

            gpu = {
              apply_gpu_optimisations = "accept-responsibility";
              gpu_device = 0;

              # NVIDIA PowerMizer: prefer maximum performance while active.
              nv_powermizer_mode = 1;
            };
          };
        };

        # Available for per-game launch configs; not forced globally.
        gamescope = {
          enable = true;
          capSysNice = true;
        };
      };

      users.extraGroups.gamemode.members = [ config.preferences.user.name ];

      # Wine/Proton esync exhausts the default 1024 fd limit.
      security.pam.loginLimits = [
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = "524288";
        }
        {
          domain = "*";
          type = "hard";
          item = "nofile";
          value = "524288";
        }
      ];

      systemd = {
        settings.Manager.DefaultLimitNOFILE = 524288;

        user.extraConfig = ''
          DefaultLimitNOFILE=524288
        '';
      };

      # Wine runs unprivileged and needs direct access to the ntsync device.
      services.udev.extraRules = ''
        KERNEL=="ntsync", MODE="0666"
      '';

      environment = {
        systemPackages = with pkgs; [
          protonup-ng
          lutris
          bottles
          prismlauncher
          vulkan-tools
          mangohud

          # Run non-Nix binaries (game tools, mod managers) in an FHS env.
          steam-run
        ];

        sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${config.preferences.user.name}/.steam/root/compatibilitytools.d";
      };
    };
}
