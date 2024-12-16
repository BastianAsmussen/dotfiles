{
  enable = true;

  disableNetrw = true;
  hijackCursor = true;
  syncRootWithCwd = true;
  updateFocusedFile = {
    enable = true;

    updateRoot = true;
  };

  view = {
    preserveWindowProportions = true;
    side = "right";
  };

  renderer = {
    rootFolderLabel = false;
    highlightGit = true;
    indentMarkers.enable = true;
    icons = {
      gitPlacement = "signcolumn";
      glyphs = {
        default = "󰈚";
        folder = {
          default = "";
          empty = "";
          emptyOpen = "";
          open = "";
          symlink = "";
        };

        git.unmerged = " ";
      };
    };
  };
}
