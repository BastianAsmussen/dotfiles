{lib, ...}: {
  programs.nixvim.plugins.rustaceanvim = {
    enable = true;

    settings.server = {
      auto_attach = true;

      default_settings.rust-analyzer = {
        cargo.extraEnv.RUSTFLAGS = lib.strings.concatStrings [
          "-Dclippy::enum_glob_use" # Disallow use of `use` of all enums.
          "-Dclippy::pedantic" # Enable all pedantic lints.
          "-Dclippy::nursery" # Enable all nursery lints.
          "-Dclippy::unwrap_used" # Disallow use of `unwrap`.
        ];

        diagnostics.styleLints.enable = true;
        files.excludeDirs = [".devenv"];
      };
    };
  };
}
