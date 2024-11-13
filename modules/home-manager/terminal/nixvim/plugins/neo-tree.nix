{
  programs.nixvim = {
    # Disable netrw.
    globals = {
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;
    };

    plugins.neo-tree = {
    enable = true;

    enableGitStatus = true;
    enableModifiedMarkers = true;
    enableRefreshOnWrite = true;
    sources = [
      "filesystem"
      "buffers"
      "git_status"
      "document_symbols"
    ];

    addBlankLineAtTop = false;
    hideRootNode = true;
    filesystem = {
      followCurrentFile.enabled = true;
      filteredItems.hideDotfiles = false;
    };

    window.width = 32;
    defaultComponentConfigs = {
      indent.withExpanders = true;
      gitStatus.symbols = {
        added = " ";
        conflict = "󰩌 ";
        deleted = "󱂥";
        ignored = " ";
        modified = " ";
        renamed = "󰑕";
        staged = "󰩍";
        unstaged = "";
        untracked = "";
      };
    };
  };
};
}
