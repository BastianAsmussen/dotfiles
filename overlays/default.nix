{inputs, ...}: {
  # Bring our custom packages from the 'pkgs' directory into scope.
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # User-defined overlays.
  modifications = _final: prev: {
    docker = prev.docker.override {
      initSupport = true;
    };
  };

  # Convenient access to the nixpkgs stable branch.
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      inherit (final) system;

      config.allowUnfree = true;
    };
  };
}
