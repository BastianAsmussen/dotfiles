{lib, ...}: {
  imports = [
    ./nginx.nix
  ];

  options.web.enable = lib.mkEnableOption "Enables web related services.";
}
