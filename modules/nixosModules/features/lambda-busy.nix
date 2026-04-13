{
  flake.nixosModules.lambdaBusy = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkOption mkEnableOption mkIf types;

    cfg = config.lambdaBusy;

    notifyScript = pkgs.writeShellScript "lambda-notify-eta" ''
      ${lib.getExe pkgs.openssh} \
        -o StrictHostKeyChecking=accept-new \
        -o ConnectTimeout=5 \
        -o BatchMode=yes \
        -i "${config.sops.secrets."builder-ssh-private-key".path}" \
        "builder@${cfg.etaHost}" \
        "/run/current-system/sw/bin/lambda-mirror-ctl $1"
    '';
  in {
    options.lambdaBusy = {
      enable = mkEnableOption ''
        Signal eta when lambda is busy (e.g. gaming) so it stops proxying
        nix cache traffic here.
      '';

      etaHost = mkOption {
        type = types.str;
        default = "eta";
        description = "Tailscale hostname or IP address of the eta machine.";
      };
    };

    config = mkIf cfg.enable {
      # The gamemode custom hooks run as the logged-in user, so the SSH key
      # must be readable by that user.  A dedicated key pair would be more
      # restrictive; for now we reuse the builder key.
      sops.secrets."builder-ssh-private-key" = {
        owner = config.preferences.user.name;
      };

      programs.gamemode.settings.custom = {
        start = "${notifyScript} busy";
        end = "${notifyScript} available";
      };
    };
  };
}
