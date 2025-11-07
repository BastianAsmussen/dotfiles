{self, ...}: {
  flake.nixosModules.general = {
    pkgs,
    config,
    ...
  }: let
    inherit (config.preferences.user) description icon;

    username = config.preferences.user.name;
  in {
    imports = [
      self.nixosModules.extra_hjem
      self.nixosModules.gtk
      self.nixosModules.nix
    ];

    users.users.${username} = {
      isNormalUser = true;
      description = "${description}";
      extraGroups = ["wheel" "networkmanager"];
      shell = self.packages.${pkgs.system}.environment;

      initialPassword = "Password123!";
      hashedPasswordFile = "/persist/passwd";
    };

    persistence = {
      data.directories = [
        "dotfiles"

        "Videos"
        "Documents"
        "Projects"

        ".ssh"
      ];

      # TODO: Remove this.
      cache.directories = [
        ".local/share/nvim"
        ".local/share/fish"

        ".config/nvim"
      ];
    };

    # Set the user's icon.
    system.activationScripts.script.text = ''
      mkdir -p /var/lib/AccountsService/{icons,users}

      cp ${icon} /var/lib/AccountsService/icons/${username}
      echo -e "[User]\nIcon=/var/lib/AccountsService/icons/${username}\n" > /var/lib/AccountsService/users/${username}
    '';
  };
}
