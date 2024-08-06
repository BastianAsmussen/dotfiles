{
  programs.nixvim = {
    plugins.neo-tree = {
      enable = true;

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
