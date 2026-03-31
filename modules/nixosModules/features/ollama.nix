{
  flake.nixosModules.ollama = {pkgs, ...}: {
    services = {
      ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
      };

      open-webui.enable = true;
    };
  };
}
