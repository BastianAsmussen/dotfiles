{
  userInfo,
  inputs,
  ...
}: let
  inherit (userInfo) username;
in {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  users = {
    mutableUsers = false;
    users = {
      root.hashedPasswordFile = "/persist/passwords/root";
      ${username}.hashedPasswordFile = "/persist/passwords/${username}";
    };
  };

  fileSystems."/persist".neededForBoot = true;
  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/etc/nix"
      "/etc/NetworkManager/system-connections"
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/libvirt"
      "/var/lib/pipewire"
      "/var/lib/bluetooth"
      "/var/db/sudo"
    ];

    files = [
      "/etc/machine-id"
    ];
  };

  systemd.tmpfiles.rules = [
    "L /var/lib/NetworkManager/secret_key - - - - /persist/var/lib/NetworkManager/secret_key"
    "L /var/lib/NetworkManager/seen-bssids - - - - /persist/var/lib/NetworkManager/seen-bssids"
    "L /var/lib/NetworkManager/timestamps - - - - /persist/var/lib/NetworkManager/timestamps"
  ];

  programs.fuse.userAllowOther = true;
}
