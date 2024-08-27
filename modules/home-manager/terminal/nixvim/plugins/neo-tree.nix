{
  programs.nixvim.plugins.neo-tree = {
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
}
