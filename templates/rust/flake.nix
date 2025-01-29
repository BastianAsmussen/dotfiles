{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-analyzer-src.follows = "";
      };
    };

    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    crane,
    fenix,
    flake-utils,
    advisory-db,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      inherit (pkgs) lib;

      craneLib = crane.mkLib pkgs;
      src = ./.;

      # Common arguments can be set here to avoid repeating them later.
      commonArgs = {
        inherit src;

        strictDeps = true;
        buildInputs = lib.optionals pkgs.stdenv.isDarwin (with pkgs; [
          libiconv
        ]);

        # Additional environment variables can be set directly.
        # RUST_BACKTRACE = "1";
      };

      craneLibLLvmTools =
        craneLib.overrideToolchain
        (fenix.packages.${system}.complete.withComponents [
          "cargo"
          "llvm-tools"
          "rustc"
        ]);

      # Build *just* the cargo dependencies, so we can reuse all of that work
      # (e.g. via cachix) when running in CI.
      cargoArtifacts = craneLib.buildDepsOnly commonArgs;

      # Build the actual crate itself, reusing the dependency artifacts from
      # above.
      crate = craneLib.buildPackage (commonArgs
        // {
          inherit cargoArtifacts;
        });
    in {
      checks = {
        # Build the crate as part of `nix flake check` for convenience.
        inherit crate;

        # Run clippy (and deny all warnings) on the crate source, again,
        # reusing the dependency artifacts from above.
        #
        # Note that this is done as a separate derivation so that we can block
        # the CI if there are issues here, but not prevent downstream
        # consumers from building our crate by itself.
        crate-clippy = craneLib.cargoClippy (commonArgs
          // {
            inherit cargoArtifacts;

            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          });

        crate-doc = craneLib.cargoDoc (commonArgs
          // {
            inherit cargoArtifacts;
          });

        # Check formatting.
        crate-fmt = craneLib.cargoFmt {
          inherit src;
        };

        crate-toml-fmt = craneLib.taploFmt {
          src = pkgs.lib.sources.sourceFilesBySuffices src [".toml"];
        };

        # Audit dependencies.
        crate-audit = craneLib.cargoAudit {
          inherit src advisory-db;
        };

        # Audit licenses.
        crate-deny = craneLib.cargoDeny {
          inherit src;
        };

        # Run tests with `cargo-nextest`.
        crate-nextest = craneLib.cargoNextest (commonArgs
          // {
            inherit cargoArtifacts;

            partitions = 1;
            partitionType = "count";
            cargoNextestPartitionsExtraArgs = "--no-tests=pass";
          });
      };

      packages =
        {
          default = crate;
        }
        // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
          crate-llvm-coverage = craneLibLLvmTools.cargoLlvmCov (commonArgs
            // {
              inherit cargoArtifacts;
            });
        };

      apps.default = flake-utils.lib.mkApp {
        drv = crate;
      };

      devShells.default = craneLib.devShell {
        # Inherit inputs from checks.
        checks = self.checks.${system};

        # Additional dev-shell environment variables can be set here directly.
        # MY_CUSTOM_DEVELOPMENT_VAR = "something else";

        # Extra inputs can be added here; cargo and rustc are provided by default.
        # packages = with pkgs; [
        #   bacon
        # ];
      };
    });
}
