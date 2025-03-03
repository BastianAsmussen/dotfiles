{inputs, ...}: {
  # Bring our custom packages from the 'pkgs' directory into scope.
  additions = final: _: import ../pkgs {pkgs = final;};

  # User-defined overlays.
  modifications = _: prev: {
    docker = prev.docker.override {
      initSupport = true;
    };
  };

  # Custom nixpkgs fork.
  fork = final: _: {
    fork = import inputs.nixpkgs-fork {
      inherit (final) system;

      config.allowUnfree = true;
    };
  };

  # Convenient access to the nixpkgs stable branch.
  stable-packages = final: _: {
    stable = import inputs.nixpkgs-stable {
      inherit (final) system;

      config.allowUnfree = true;
    };
  };
}
