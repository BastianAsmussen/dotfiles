{
  programs.nixvim.plugins.lualine = {
    enable = true;

    globalstatus = true;
    componentSeparators = {
      left = "|";
      right = "|";
    };

    sectionSeparators = {
      left = "";
      right = "";
    };

    sections = {
      lualine_a = ["mode"];
      lualine_b = ["branch"];
      lualine_c = [
        "filename"
        "diff"
      ];

      lualine_x = [
        "diagnostics"
        "encoding"
        "fileformat"
        "filetype"
      ];
    };
  };
}
