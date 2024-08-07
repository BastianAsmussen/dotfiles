{
  programs.nixvim = {
    plugins.neo-tree = {
      enable = true;

      closeIfLastWindow = true;
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
        action = ":Neotree<CR>";
      }
    ];
  };
}
