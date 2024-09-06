{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption types mkOption mkIf;

  cfg = config.kubernetes;
in {
  options.kubernetes = {
    enable = mkEnableOption "Enable Kubernetes locally.";
    master = mkOption {
      type = types.submodule {
        options = {
          ip = mkOption {
            default = "127.0.0.1";
            description = "The master IP that Kubernetes will use.";
            type = types.str;
          };

          hostname = mkOption {
            default = "api.kube";
            description = "The master hostname that Kubernetes will use.";
            type = types.str;
          };

          apiPort = mkOption {
            default = 6443;
            description = "The master API server port that Kubernetes will use.";
            type = types.int;
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    networking.extraHosts = "${cfg.master.ip} ${cfg.master.hostname}";
    environment.systemPackages = with pkgs; [
      kompose
      kubectl
      kubernetes
    ];

    services.kubernetes = {
      roles = ["master" "node"];
      masterAddress = cfg.master.hostname;
      apiserverAddress = "https://${cfg.master.hostname}:${toString cfg.master.apiPort}";
      easyCerts = true;
      apiserver = {
        securePort = cfg.master.apiPort;
        advertiseAddress = cfg.master.ip;
      };

      addons.dns.enable = true;
      kubelet.extraOpts = "--fail-swap-on=false";
    };
  };
}
