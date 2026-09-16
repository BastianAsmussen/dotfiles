{
  flake.homeModules.obsidian = {
    programs.obsidian = {
      enable = true;

      vaults.notes.target = "Documents/Obsidian";
      defaultSettings.app = {
        alwaysUpdateLinks = true;
        spellcheck = true;
      };
    };

    persistence.directories = [ ".config/obsidian" ];
  };
}
