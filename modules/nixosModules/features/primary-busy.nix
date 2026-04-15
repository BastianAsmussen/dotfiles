{
  flake.nixosModules.primaryBusy = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkOption mkEnableOption mkIf types;

    cfg = config.primaryBusy;

    notifyScript = pkgs.writeShellScript "primary-notify-mirror" ''
      ${lib.getExe pkgs.openssh} \
        -o StrictHostKeyChecking=accept-new \
        -o ConnectTimeout=5 \
        -o BatchMode=yes \
        -i "${config.sops.secrets."hosts/${config.networking.hostName}/builder-ssh-private-key".path}" \
        "builder@${cfg.mirrorHost}" \
        "/run/current-system/sw/bin/primary-mirror-ctl $1"
    '';
  in {
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
    };

    config = mkIf cfg.enable {
      # Let the desktop user read the builder key used by gamemode's SSH hooks.
      sops.secrets."hosts/${config.networking.hostName}/builder-ssh-private-key" = {
        owner = config.preferences.user.name;
      };

      programs.gamemode.settings.custom = {
        start = "${notifyScript} busy";
        end = "${notifyScript} available";
      };
    };
  };
}
