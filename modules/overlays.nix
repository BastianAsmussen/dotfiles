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
