{
  flake.homeModules.zoxide = {
    home.shellAliases."cd.." = "cd ..";

    programs.zoxide = {
      enable = true;
      options = [ "--cmd cd" ];
    };

    persistence.directories = [ ".local/share/zoxide" ];
  };
}
