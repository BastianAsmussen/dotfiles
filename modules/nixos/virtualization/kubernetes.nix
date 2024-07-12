{
  lib,
  config,
  pkgs,
  ...
}: {
  options.kubernetes.enable = lib.mkEnableOption "Enable Kubernetes locally.";

  config = lib.mkIf config.kubernetes.enable {
    environment.systemPackages = with pkgs; [
      minikube
    ];
  };
}
