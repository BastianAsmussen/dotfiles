{inputs, ...}: {
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  programs.nixvim = {
    enable = true;

    plugins.lsp = {
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
}
