{
  lib,
  osConfig,
  pkgs,
  ...
}: {
  programs.obs-studio = {
    enable = true;

    package = lib.mkIf osConfig.nvidia.enable (pkgs.obs-studio.override {
      cudaSupport = true;
    });
  };
}
