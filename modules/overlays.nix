{
  withSystem,
  inputs,
  ...
}: {
  flake.overlays = {
    # Bring our custom packages into scope.
    additions = _: prev:
      withSystem prev.stdenv.hostPlatform.system (
        {config, ...}: config.packages
      );

    # User-defined overlays.
    modifications = _: prev: {
      docker = prev.docker.override {
        initSupport = true;
      };

      bottles = prev.bottles.override {
        removeWarningPopup = true;
      };
    };

    # Custom nixpkgs fork.
    fork = _: prev: {
      fork = withSystem prev.stdenv.hostPlatform.system (
        import inputs.nixpkgs-fork {
          config.allowUnfree = true;
        }
      );
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
