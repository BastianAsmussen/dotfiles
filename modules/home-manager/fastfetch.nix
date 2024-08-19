{
  programs.fastfetch = {
    enable = true;

    settings = {
      display = {
        separator = "";
        key.width = 15;
      };

      modules = [
        {
          key = "╭───────────╮";
          type = "custom";
        }
        {
          # Draw borders first to make colors of left and right border consistent.
          key = "│ {#31} user    {#keys}│";
          type = "title";
          format = "{1}";
        }
        {
          key = "│ {#32}󰇅 host    {#keys}│";
          type = "title";
          format = "{2}";
        }
        {
          key = "│ {#33}󰅐 uptime  {#keys}│";
          type = "uptime";
        }
        {
          key = "│ {#39}󰟾 distro  {#keys}│";
          type = "os";
        }
        {
          key = "│ {#34} pkgs    {#keys}│";
          type = "packages";
        }
        {
          key = "│ {#35} kernel  {#keys}│";
          type = "kernel";
        }
        {
          key = "│ {#36}󰇄 desktop {#keys}│";
          type = "de";
        }
        {
          key = "│ {#31} term    {#keys}│";
          type = "terminal";
        }
        {
          key = "│ {#32} shell   {#keys}│";
          type = "shell";
        }
        {
          key = "│ {#33}󰍛 cpu     {#keys}│";
          type = "cpu";
          showPeCoreCount = true;
          temp = true;
        }
        {
          key = "│ {#39}󰢮 gpu     {#keys}│";
          type = "gpu";
          temp = true;
        }
        {
          key = "│ {#34}󰉉 disk    {#keys}│";
          type = "disk";
          folders = "/";
        }
        {
          key = "│ {#35} memory  {#keys}│";
          type = "memory";
        }
        {
          key = "├───────────┤";
          type = "custom";
        }
        {
          key = "│ {#39} colors  {#keys}│";
          type = "colors";
          symbol = "circle";
        }
        {
          key = "╰───────────╯";
          type = "custom";
        }
      ];
    };
  };
}
