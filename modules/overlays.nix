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
            deepseek-harness
            mit
            qbittorrent-webui-catppuccin
            absolute-episode
            calculator
            caveman-cli
            copy-file
            neovim
            neovim-minimal
            repo-cloner
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

      # Fix fish 4's removed `test -a` and make PROG global for completions.
      gopass = prev.gopass.overrideAttrs (old: {
        postPatch =
          (old.postPatch or "")
          +
          # fish
          ''
            substituteInPlace fish.completion \
              --replace-fail '[ (count $cmd) -eq 1 -a $cmd[1] = $PROG ]' \
                '[ (count $cmd) -eq 1 ]; and [ "$cmd[1]" = gopass ]'
          '';
      });
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
