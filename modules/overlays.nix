{
  withSystem,
  inputs,
  ...
}: {
  flake.overlays = {
    # Bring our custom packages into scope.
    additions = _: prev:
      withSystem prev.stdenv.hostPlatform.system (
        {config, ...}: {inherit (config) packages;}
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
    fork = final: _: {
      fork = import inputs.nixpkgs-fork {
        inherit (final.stdenv.hostPlatform) system;

        config.allowUnfree = true;
      };
    };

    # Convenient access to the nixpkgs stable branch.
    stable-packages = final: _: {
      stable = import inputs.nixpkgs-stable {
        inherit (final.stdenv.hostPlatform) system;

        config.allowUnfree = true;
      };
    };
  };
}
