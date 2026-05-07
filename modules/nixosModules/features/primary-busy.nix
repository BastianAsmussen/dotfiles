{ inputs, ... }:
{
  flake.nixosModules.primaryBusy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        mkEnableOption
        mkIf
        mkOption
        types
        ;

      cfg = config.primaryBusy;

      inherit (config.networking) hostName;

      notifyScript = pkgs.writeShellScript "primary-notify-mirror" ''
        ${lib.getExe pkgs.openssh} \
          -o StrictHostKeyChecking=accept-new \
          -o ConnectTimeout=5 \
          -o BatchMode=yes \
          -i "${config.sops.secrets.${cfg.sshKeySecret}.path}" \
          "${cfg.sshUser}@${cfg.mirrorHost}" \
          "$1"
      '';

      syncScript = pkgs.writeShellScript "primary-busy-sync" ''
        if [ -n "$(${lib.getExe' pkgs.gamemode "gamemodelist"} 2>/dev/null)" ]; then
          ${notifyScript} busy
        else
          ${notifyScript} available
        fi
      '';
    in
    {
      options.primaryBusy = {
        enable = mkEnableOption ''
          Signal the mirror host when this machine is busy so it stops proxying
          traffic here.
        '';

        mirrorHost = mkOption {
          type = types.str;
          default = "10.10.0.1";
          description = "WireGuard IP address of the mirror host.";
        };

        sshUser = mkOption {
          type = types.str;
          default = "primary-busy";
          description = "Remote SSH user used to update primary mirror state.";
        };

        sshKeySecret = mkOption {
          type = types.str;
          default = "hosts/${hostName}/primary-busy-ssh-private-key";
          description = "SOPS secret containing the SSH key used for busy-state updates.";
        };

        syncInterval = mkOption {
          type = types.ints.positive;
          default = 60;
          description = "How often, in seconds, to sync gamemode state to the mirror host.";
        };
      };

      config = mkIf cfg.enable {
        programs.ssh.knownHosts."eta-wg" = {
          hostNames = [ cfg.mirrorHost ];
          publicKey = inputs.nix-secrets.hosts.eta.ssh-public-key;
        };

        sops.secrets.${cfg.sshKeySecret} = {
          owner = config.preferences.user.name;
          mode = "0400";
        };

        programs.gamemode.settings.custom = {
          start = "${notifyScript} busy";
          end = "${notifyScript} available";
        };

        systemd = {
          services.primary-busy-sync = {
            description = "Sync gamemode busy state to mirror host";
            after = [
              "network-online.target"
              "wireguard-wg0.service"
            ];
            wants = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = syncScript;
            };
          };

          timers.primary-busy-sync = {
            description = "Periodic gamemode state sync to mirror host";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "30s";
              OnUnitActiveSec = "${toString cfg.syncInterval}s";
            };
          };
        };
      };
    };
}
