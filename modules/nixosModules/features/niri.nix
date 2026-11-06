{
  inputs,
  self,
  ...
}:
{
  flake.nixosModules.niri =
    {
      pkgs,
      lib,
      config,
      options,
      ...
    }:
    let
      toStartupEntry =
        i: entry:
        if lib.isDerivation entry then
          lib.getExe entry
        else
          "${pkgs.writeShellScript "autostart-${toString i}" entry}";

      autostartEntries = lib.imap0 toStartupEntry config.preferences.autostart;
      monitorsToOutputs = lib.mapAttrs (
        _: m:
        {
          mode = "${toString m.width}x${toString m.height}@${toString m.refreshRate}";
          position = _: {
            props = {
              inherit (m) x y;
            };
          };

          inherit (m) scale;
        }
        // lib.optionalAttrs (m.vrr != "off") {
          "variable-refresh-rate" =
            if m.vrr == "on-demand" then
              _: {
                props = {
                  "on-demand" = true;
                };
              }
            else
              _: { };
        }
      ) (lib.filterAttrs (_: m: m.enabled) config.preferences.monitors);
    in
    {
      config = lib.mkMerge [
        {
          preferences.autostart = [ config.programs.noctalia.package ];

          programs = {
            niri = {
              enable = true;
              package = inputs.wrapper-modules.wrappers.niri.wrap {
                inherit pkgs;

                imports = [
                  self.wrapperModules.niri
                  {
                    settings = {
                      spawn-at-startup = autostartEntries;
                      outputs = monitorsToOutputs;
                    };
                  }
                ];
              };
            };

            noctalia = {
              enable = true;
              package = self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia.wrap {
                inherit (config.preferences.noctalia)
                  useIpLocation
                  idleEnabled
                  powerProfileEnabled
                  screenshotDirectory
                  ;
              };
            };
          };

          systemd.user.services.noctalia-bar-watcher = {
            wantedBy = [ "graphical-session.target" ];
            partOf = [ "graphical-session.target" ];
            after = [ "graphical-session.target" ];
            path = [
              config.programs.niri.package
              config.programs.noctalia.package
            ];

            serviceConfig = {
              ExecStart = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-bar-watcher;
              Restart = "on-failure";
              RestartSec = 2;
            };
          };

          environment.systemPackages = with pkgs; [
            xwayland-satellite
            awww
            wl-clipboard
            alsa-utils
          ];

          security.polkit.enable = true;
          services = {
            displayManager.defaultSession = lib.mkDefault "niri";
            power-profiles-daemon.enable = true;
            upower.enable = true;
          };

          hardware.bluetooth = {
            enable = lib.mkDefault true;
            powerOnBoot = lib.mkDefault true;
          };

          xdg.portal = {
            enable = true;
            extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          };

          fonts.packages = with pkgs; [
            nerd-fonts.jetbrains-mono
          ];

          fonts.fontconfig.defaultFonts.monospace = [ "JetBrainsMono Nerd Font" ];
        }

        # Noctalia replaces files by rename, so persist the whole directory.
        (lib.optionalAttrs (options ? persistence) {
          persistence.user.directoriesWithMode.".local/state/noctalia" = "0700";

          # Remove GUI overrides so the generated config stays authoritative.
          systemd.tmpfiles.rules = lib.mkIf config.persistence.enable [
            "r ${config.users.users.${config.preferences.user.name}.home}/.local/state/noctalia/settings.toml"
          ];
        })
      ];
    };
}
