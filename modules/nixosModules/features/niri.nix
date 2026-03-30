{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.niri = {
    pkgs,
    lib,
    config,
    ...
  }: let
    inherit (pkgs.stdenv.hostPlatform) system;

    toStartupEntry = i: entry:
      if lib.isDerivation entry
      then lib.getExe entry
      else "${pkgs.writeShellScript "autostart-${toString i}" entry}";

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
        // lib.optionalAttrs m.vrr {variable-refresh-rate = _: {};}
    ) (lib.filterAttrs (_: m: m.enabled) config.preferences.monitors);
  in {
    config = {
      preferences.autostart = [self.packages.${system}.noctalia-shell];

      services.displayManager.defaultSession = lib.mkDefault "niri";
      programs.niri = {
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

      environment.systemPackages = [
        self.packages.${system}.noctalia-shell
        pkgs.xwayland-satellite
        pkgs.swww
        pkgs.grim
        pkgs.slurp
        pkgs.swappy
        pkgs.wl-clipboard
        pkgs.alsa-utils
      ];

      security.polkit.enable = true;
      services.upower.enable = true;
      hardware.bluetooth = {
        enable = lib.mkDefault true;
        powerOnBoot = lib.mkDefault true;
      };

      xdg.portal = {
        enable = true;
        extraPortals = [pkgs.xdg-desktop-portal-gtk];
      };

      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
      ];

      fonts.fontconfig.defaultFonts = {
        monospace = ["JetBrainsMono Nerd Font"];
      };
    };
  };
}
