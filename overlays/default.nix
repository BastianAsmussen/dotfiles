{inputs, ...}: {
  # Bring our custom packages from the 'pkgs' directory into scope.
  additions = final: _: import ../pkgs {pkgs = final;};

  # User-defined overlays.
  modifications = _: prev: {
    docker = prev.docker.override {
      initSupport = true;
    };

    # Temporary solution to nixpkgs issue #380196.
    lldb = prev.lldb.overrideAttrs {
      dontCheckForBrokenSymlinks = true;
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
