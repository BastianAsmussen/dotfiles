{inputs, ...}: {
  # Bring our custom packages from the 'pkgs' directory into scope.
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # User-defined overlays.
  modifications = final: _prev: {
    docker-overlay = import inputs.docker-overlay {
      inherit (final) system;

      config.allowUnfree = true;
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
