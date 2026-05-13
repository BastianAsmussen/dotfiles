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
      boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto.extend (
        _: prev: {
          kernel = prev.kernel.override { stdenv = pkgs.ccacheStdenv; };
        }
      );

      programs = {
        steam = {
          enable = true;
          gamescopeSession.enable = true;

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

        gamemode.enable = true;
      };

      users.extraGroups.gamemode.members = [ config.preferences.user.name ];
      environment = {
        systemPackages = with pkgs; [
          protonup-ng
          lutris
          bottles
          prismlauncher
        ];

        sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${config.preferences.user.name}/.steam/root/compatibilitytools.d";
      };
    };
}
