{
  programs.nixvim = {
    plugins.neo-tree = {
      enable = true;

      enableGitStatus = true;
      enableModifiedMarkers = true;
      enableRefreshOnWrite = true;
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
