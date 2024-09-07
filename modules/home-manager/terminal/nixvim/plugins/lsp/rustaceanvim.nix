{
  programs.nixvim.plugins.rustaceanvim = {
    enable = true;

    settings.server.default_settings.rust-analyzer = {
      cargo.extraEnv.RUSTFLAGS = builtins.concatStringsSep " " [
        "-Dclippy::enum_glob_use" # Disallow use of `use` of all enums.
        "-Dclippy::pedantic" # Enable all pedantic lints.
        "-Dclippy::nursery" # Enable all nursery lints.
        "-Dclippy::unwrap_used" # Disallow use of `unwrap`.
      ];

      check.command = "clippy";

      diagnostics.styleLints.enable = true;
      inlayHints.lifetimeElisionHints.enable = "always";
      files.excludeDirs = [
        ".devenv"
      ];
    };
  };
}
