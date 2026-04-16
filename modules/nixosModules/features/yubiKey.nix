{
  flake.nixosModules.yubiKey = {pkgs, ...}: {
    services = {
      udev.packages = [pkgs.yubikey-personalization];
      pcscd.enable = true;
    };

    environment.systemPackages = with pkgs; [
      yubikey-personalization
      yubioath-flutter
    ];
  };
}
