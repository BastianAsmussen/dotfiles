{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko

    ./audio.nix
    ./boot.nix
    ./desktop.nix
    ./gaming.nix
    ./nix.nix
    ./nvidia.nix
    ./security.nix
    ./users.nix
    ./virtual.nix
  ];

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_DK.UTF-8";
  console.keyMap = "dk";

  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };
}
