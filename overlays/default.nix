{inputs, ...}: {
  # Bring our custom packages from the 'pkgs' directory into scope.
  additions = final: _prev: import ../pkgs {pkgs = final;};

  docker-overlay = final: _prev: {
    docker-overlay = import inputs.docker-overlay {
      inherit (final) system;

      config.allowUnfree = true;
    };
  };
}
