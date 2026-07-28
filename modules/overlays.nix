{
  withSystem,
  inputs,
  ...
}:
{
  flake.overlays = {
    # Bring our custom packages into scope.
    additions =
      _: prev:
      withSystem prev.stdenv.hostPlatform.system (
        { config, ... }:
        {
          inherit (config.packages)
            mit
            calculator
            copy-file
            neovim
            neovim-minimal
            qbittorrent-webui-catppuccin
            repo-cloner
            todo
            tuxedo
            ;
        }
      );

    # Version-pinned, hash-locked Firefox addons (`pkgs.firefox-addons.*`).
    firefox-addons = inputs.firefox-addons.overlays.default;

    # User-defined overlays.
    modifications = _: prev: {
      bottles = prev.bottles.override {
        removeWarningPopup = true;
      };
    };

    # TODO: Remove once nixpkgs pins niri to libdisplay-info_0_3.
    niri-libdisplay-info-compat =
      _final: prev:
      let
        libdisplay-info_0_3 =
          prev.libdisplay-info_0_3 or (prev.libdisplay-info.overrideAttrs (_oldAttrs: rec {
            version = "0.3.0";

            src = prev.fetchFromGitLab {
              domain = "gitlab.freedesktop.org";
              owner = "emersion";
              repo = "libdisplay-info";
              rev = version;
              hash = "sha256-nXf2KGovNKvcchlHlzKBkAOeySMJXgxMpbi5z9gLrdc=";
            };
          }));
      in
      {
        inherit libdisplay-info_0_3;

        niri = prev.niri.override {
          libdisplay-info = libdisplay-info_0_3;
        };
      };

    # Convenient access to the nixpkgs stable branch.
    stable-packages = _: prev: {
      stable = withSystem prev.stdenv.hostPlatform.system (
        import inputs.nixpkgs-stable {
          config.allowUnfree = true;
        }
      );
    };
  };
}
