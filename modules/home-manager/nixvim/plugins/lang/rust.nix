{
  programs.nixvim = {
    plugins = {
      rustaceanvim = {
        enable = true;

        settings.server = {
          cmd = [
            "rustup"
            "run"
            "nightly"
            "rust-analyzer"
          ];

          settings.rust-analyzer = {
            check.command = "clippy";
            inlayHints.lifetimeElisionHints.enable = "always";
          };
        };
      };

      crates-nvim.enable = true;
    };
  };
}
