{
  lib,
  config,
  pkgs,
  ...
}: let
  kubeMasterIP = "127.0.0.1";
  kubeMasterHostname = "api.kube";
  kubeMasterAPIServerPort = 6443;
in {
  options.kubernetes.enable = lib.mkEnableOption "Enable Kubernetes locally.";

  config = lib.mkIf config.kubernetes.enable {
    networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";
    environment.systemPackages = with pkgs; [
      kompose
      kubectl
      kubernetes
    ];

    services.kubernetes = {
      roles = ["master" "node"];
      masterAddress = kubeMasterHostname;
      apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
      easyCerts = true;
      apiserver = {
        securePort = kubeMasterAPIServerPort;
        advertiseAddress = kubeMasterIP;
      };

      addons.dns.enable = true;
      kubelet.extraOpts = "--fail-swap-on=false";
    };
  };
}
