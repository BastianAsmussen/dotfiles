{inputs, ...}: {
  # Bring our custom packages from the 'pkgs' directory into scope.
  additions = final: _: import ../pkgs {pkgs = final;};

  # User-defined overlays.
  modifications = _: prev: {
    docker-init = prev.docker-init.overrideAttrs (old: {
      src = prev.fetchurl {
        url = "https://desktop.docker.com/linux/main/amd64/${old.tag}/docker-desktop-x86_64.pkg.tar.zst";
        hash = "sha256-pxxlSN2sQqlPUzUPufcK8T+pvdr0cK+9hWTYzwMJv5I=";
      };
    });

    docker = prev.docker.override {
      initSupport = true;
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
