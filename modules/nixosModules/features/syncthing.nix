{inputs, ...}: {
  flake.nixosModules.syncthing = {
    config,
    lib,
    ...
  }: let
    inherit (inputs.nix-secrets) hosts;

    user = config.preferences.user.name;
    home = "/home/${user}";

    devices = {
      epsilon.id = hosts.epsilon.syncthing-id;
      delta.id = hosts.delta.syncthing-id;
    };

    # All hosts share the same folder declarations; each host syncs with the
    # other devices in the list (Syncthing silently ignores its own ID).
    allDevices = lib.attrNames devices;
  in {
    sops.secrets = {
      "hosts/${config.networking.hostName}/syncthing-key".owner = user;
      "hosts/${config.networking.hostName}/syncthing-cert".owner = user;
      "services/syncthing/gui-password".owner = user;
    };

    services.syncthing = {
      inherit user;

      enable = true;
      group = "users";
      dataDir = home;
      cert = config.sops.secrets."hosts/${config.networking.hostName}/syncthing-cert".path;
      key = config.sops.secrets."hosts/${config.networking.hostName}/syncthing-key".path;
      guiPasswordFile = config.sops.secrets."services/syncthing/gui-password".path;
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        inherit devices;

        options.urAccepted = -1;
        gui = {
          inherit user;

          insecureSkipHostcheck = true;
          theme = "dark";
        };

        folders = {
          "Documents" = {
            path = "${home}/Documents";
            devices = allDevices;
          };

          "Pictures" = {
            path = "${home}/Pictures";
            devices = allDevices;
          };

          "Videos" = {
            path = "${home}/Videos";
            devices = allDevices;
          };
        };
      };
    };
  };
}
