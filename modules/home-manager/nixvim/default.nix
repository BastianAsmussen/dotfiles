{inputs, ...}: {
  imports = [
    ./plugins

    inputs.nixvim.homeManagerModules.nixvim
  ];

  programs.nixvim = {
    enable = true;

    opts = {
      number = true;
      shiftwidth = 4;
    };

    plugins = {
      lsp = {
        enable = true;

        servers = {
          rust-analyzer = {
            enable = true;

            # Provided by dev shells.
            installRustc = false;
            installCargo = false;
          };
        };
      };
    };
  };
}
