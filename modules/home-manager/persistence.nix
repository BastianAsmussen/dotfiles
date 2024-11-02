{
  inputs,
  lib,
  osConfig,
  ...
}: {
  imports = [
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];

  home.persistence."/persist/home" = {
    directories = [
      "Downloads"
      "Music"
      "Pictures"
      "Videos"
      ".gnupg"
      ".ssh"
      ".local/share/keyrings"
      ".local/share/direnv"
      (lib.mkIf osConfig.gaming.enable {
        directory = ".local/share/Steam";
        method = "symlink";
      })
    ];

    allowOther = true;
  };
}
