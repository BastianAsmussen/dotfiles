{pkgs ? import <nixpkgs> {}}: let
  overrides = builtins.fromTOML (builtins.readFile ./rust-toolchain.toml);
  libPath = with pkgs;
    lib.makeLibraryPath [];
in
  pkgs.mkShell rec {
    name = "rust";
    buildInputs = with pkgs; [
      clang
      llvmPackages.bintools
      rustup
    ];

    RUSTC_VERSION = overrides.toolchain.channel;
    LIBCLANG_PATH = pkgs.lib.makeLibraryPath [pkgs.llvmPackages_latest.libclang.lib];

    shellHook = ''
      export PATH=$PATH:''${CARGO_HOME:-~/.cargo}/bin
      export PATH=$PATH:''${RUSTUP_HOME:-~/.rustup}/toolchains/$RUSTC_VERSION-x86_64-unknown-linux-gnu/bin/
    '';

    # Add precompiled library to rustc search path.
    RUSTFLAGS = builtins.map (a: ''-L ${a}/lib'') [];

    LD_LIBRARY_PATH = libPath;

    # Add glibc, clang, glib, and other headers to bindgen search path.
    BINDGEN_EXTRA_CLANG_ARGS =
      # Includes normal include path.
      (builtins.map (a: ''-I"${a}/include"'') [
        pkgs.glibc.dev
      ])
      # Includes with special directory paths.
      ++ [
        ''-I"${pkgs.llvmPackages_latest.libclang.lib}/lib/clang/${pkgs.llvmPackages_latest.libclang.version}/include"''
        ''-I"${pkgs.glib.dev}/include/glib-2.0"''
        ''-I${pkgs.glib.out}/lib/glib-2.0/include/''
      ];
  }
