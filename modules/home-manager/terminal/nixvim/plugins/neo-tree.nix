{
  programs.nixvim.plugins.neo-tree = {
    enable = true;

    enableGitStatus = true;
    enableModifiedMarkers = true;
    enableRefreshOnWrite = true;

    hideRootNode = true;

    filesystem.filteredItems.hideDotfiles = false;
    window.width = 32;
  };
}
