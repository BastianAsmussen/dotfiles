{
  programs.nixvim = {
    plugins.neo-tree = {
      enable = true;

      window = {
        width = 32;
        autoExpandWidth = true;
      };

      enableGitStatus = true;
      enableModifiedMarkers = true;
      enableRefreshOnWrite = true;

      filesystem.filteredItems.hideDotfiles = false;
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>e";
        action = ":Neotree action=focus reveal<CR>";
        options.silent = true;
      }
    ];
  };
}
